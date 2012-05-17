#encoding: utf-8
class WordsController < ApplicationController
  require 'rexml/document'
  include REXML
  
  def index
    cookies[:user_id]=1
    cookies[:user_name]="jeffrey6052"
    #---------------------------------------------------硬写 cookies
    @user = User.find(cookies[:user_id])
    @user.init_word_list(2)  # 用户第一次登录，创建数据库记录，以及XML文件
    @user.makeup_oldwords(cookies[:user_id])  # 根据xml内容更新数据库
    if @user.user_word_relation.nil?
      redirect_to "/words"
      return false
    end
    user_id = cookies[:user_id]
    @study_time = @user.user_word_relation.all_study_time.nil? ? 0 : @user.user_word_relation.all_study_time
    @time_str = "#{(@study_time/86400).to_s.rjust(2,"0")}#{(@study_time%86400/3600).to_s.rjust(2,"0")}#{(@study_time%86400%3600/60).to_s.rjust(2,"0")}#{(@study_time%60).to_s.rjust(2,"0")}"
    @circle_data = @user.circle_data
  end

  
  def show
      
  end


  #开始学习
  def start
    record = UserWordRelation.find_by_user_id(cookies[:user_id])
    cookies[:study_role] = record.study_role
    x_url = "#{Rails.root}/public/user_word_xml/#{record.practice_url}"
    xml = get_doc(x_url)
    #XML中的单词数如果少于限制数，则补充新词,一天最多更新一次
    last_update = xml.root.elements["new_words"].attributes["update"]
    if last_update.nil? || last_update.to_date.nil? || last_update.to_date<Time.now.to_date
      xml = update_newwords(xml,cookies[:user_id])
      write_xml(xml,x_url)
    end
    #获取单词数据
    source = word_source(xml)
    if source.nil?
      render :inline=>"当天单词已背完，Congratulation :)"
      return false
    end
    @word,@web_type,@sentences,@other_words = source[:word],source[:web_type],source[:sentences],source[:other_words]

  end


  #继续学习
  def ajax_next_word
    #to be continue
    type = params[:type]
    word_id = params[:word_id]
    error = params[:error]
    record = UserWordRelation.find_by_user_id(cookies[:user_id])
    x_url = "#{Rails.root}/public/user_word_xml/#{record.practice_url}"
    xml = get_doc(x_url)
    xml = handle_recite_word(xml,word_id,error) if type=="recite"   #处理新背的单词
    xml = handle_review_word(xml,word_id,error) if type=="review"   #处理复习的单词
    write_xml(xml,x_url)
    render :partial=>"/words/ajax_source",:object=>word_source(xml)
  end

  #已经掌握
  def ajax_know_well
    #to be continue
    type = params[:type]
    word_id = params[:word_id]
    record = UserWordRelation.find_by_user_id(cookies[:user_id])
    x_url = "#{Rails.root}/public/user_word_xml/#{record.practice_url}"
    xml = get_doc(x_url)
    word_node = xml.root.elements["new_words//word[@id='#{word_id}']"] if type == "recite"
    word_node = xml.root.elements["old_words//word[@id='#{word_id}']"] if type == "review"
    xml.delete_element(word_node.xpath)
    write_xml(xml,x_url)
    recite_ids = record.recite_ids.nil? ? "" : record.recite_ids
    recite_ids = (recite_ids.split(",")<<word_id).join(",")
    record.update_attribute("recite_ids",recite_ids)
    render :partial=>"/words/ajax_source",:object=>word_source(xml)
  end
  

end
