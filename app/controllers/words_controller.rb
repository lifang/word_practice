#encoding: utf-8
class WordsController < ApplicationController
  require 'rexml/document'
  include REXML
  layout "application"
  
  def index
    cookies[:user_id]=1
    cookies[:user_name]="jeffrey6052"
    #---------------------------------------------------硬写 cookies
    @user = User.find(cookies[:user_id])
    @user.init_word_list(2)  # 用户第一次登录，创建数据库记录，以及XML文件
    @user.makeup_oldwords(cookies[:user_id])  # 根据xml内容更新数据库   
    @record = @user.user_word_relation
    if @record.nil?
      redirect_to "/words"
      return false
    end
    cookies[:study_role] = @record.study_role
    @study_time = @record.all_study_time.nil? ? 0 : @record.all_study_time
    @time_str = "#{(@study_time/86400).to_s.rjust(2,"0")}#{(@study_time%86400/3600).to_s.rjust(2,"0")}#{(@study_time%86400%3600/60).to_s.rjust(2,"0")}#{(@study_time%60).to_s.rjust(2,"0")}"
    @circle_data = @user.circle_data 
  end


  #开始学习
  def start
    record = UserWordRelation.find_by_user_id(cookies[:user_id])
    x_url = "#{Rails.root}/public/#{record.practice_url}"
    xml = get_doc(x_url)
    #XML中的单词数如果少于限制数，则补充新词,一天最多更新一次
    #last_update = xml.root.elements["new_words"].attributes["update"]
    #if last_update.nil? || last_update.to_date.nil? || last_update.to_date<Time.now.to_date
    xml = update_newwords(xml,cookies[:user_id])
    write_xml(xml,x_url)
    #end
    #获取单词数据
    @source = word_source(xml)
    @source.merge!({:timer => record.timer})
    if @source.nil?
      render :inline=>"当天单词已背完，Congratulation :)"
      return false
    end
    render :layout=>false
  end


  #继续学习
  def ajax_next_word
    #to be continue
    type = params[:type]
    word_id = params[:word_id]
    error = params[:error]
    record = UserWordRelation.find_by_user_id(cookies[:user_id])
    study_time = record.timer.nil? ? ((User::DEFAULT_TIMER).split(",")).to_i : (record.timer.split(",")[0]).to_i
    x_url = "#{Rails.root}/public/#{record.practice_url}"
    xml = get_doc(x_url)
    if type=="recite"   #处理新背的单词
      this_step = xml.root.elements["new_words//word[@id='#{word_id}']"].attributes["step"].to_i
      record.update_study_times(this_step == 4 ? study_time * 2 : study_time)
      xml = handle_recite_word(xml,word_id,error)
    elsif type=="review"   #处理复习的单词
      xml = handle_review_word(xml,word_id,error)
      record.update_study_times(study_time * 2)
    end
    write_xml(xml,x_url)
    source = word_source(xml)
    source.merge!({:timer => record.timer})
    if source
      render :partial=>"/words/ajax_source",:object=>source
    else
      redirect_to "/words/start"
    end
  end

  #已经掌握
  def ajax_know_well
    #to be continue
    type = params[:type]
    word_id = params[:word_id]
    record = UserWordRelation.find_by_user_id(cookies[:user_id])
    x_url = "#{Rails.root}/public/#{record.practice_url}"
    xml = get_doc(x_url)
    word_node = xml.root.elements["new_words//word[@id='#{word_id}']"] if type == "recite"
    word_node = xml.root.elements["old_words//word[@id='#{word_id}']"] if type == "review"
    xml.delete_element(word_node.xpath)
    write_xml(xml,x_url)
    recite_ids = record.recite_ids.nil? ? "" : record.recite_ids
    recite_ids = (recite_ids.split(",")<<word_id).join(",")
    record.update_attribute("recite_ids",recite_ids)
    source = word_source(xml)
    source.merge!({:timer => record.timer})
    if source
      render :partial=>"/words/ajax_source",:object=>source
    else
      redirect_to "/words/start"
    end
  end
  

end
