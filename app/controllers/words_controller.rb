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
    user_id = cookies[:user_id]
    @study_time = @user.user_word_relation.all_study_time
    @time_str = "#{(@study_time/86400).to_s.rjust(2,"0")}#{(@study_time%86400/3600).to_s.rjust(2,"0")}#{(@study_time%86400%3600/60).to_s.rjust(2,"0")}#{(@study_time%60).to_s.rjust(2,"0")}"
    @circle_data = circle_data(user_id)
  end

  
  def show
      
  end

  #返回 [已掌握 初步掌握 未掌握],如 [35,35,30],3个元素相加等于100
  def circle_data(user_id)
    result = {}
    record = UserWordRelation.find_by_user_id(user_id)
    nomal_ids = record.nomal_ids.nil? ? [] : record.nomal_ids.split(",")
    nomal_sum = nomal_ids.length
    recite_ids = record.recite_ids.nil? ? [] : record.recite_ids.split(",")
    recite_sum = recite_ids.length
    xml_file = File.open("#{Rails.root}/public/user_word_xml/#{record.practice_url}")
    xml = Document.new(xml_file)
    xml_file.close
    doing_sum = xml.get_elements("/user_words/old_words//word").length
    all_sum = recite_sum + doing_sum + nomal_sum
    circle = [recite_sum*100/all_sum , doing_sum*100/all_sum]
    circle[2] = 100 - circle[0] - circle[1]
    result[:data] = [recite_sum,doing_sum,nomal_sum]
    result[:circle] = circle
    return result
  end


  #开始学习
  def start
    #统计当天需要背诵的单词
    record = UserWordRelation.find_by_user_id(cookies[:user_id])
    xml_file = File.open("#{Rails.root}/public/user_word_xml/#{record.practice_url}")
    xml = Document.new(xml_file)
    xml_file.close
    review_date = ["#{4.day.ago.to_date}","#{3.day.ago.to_date}","#{2.day.ago.to_date}","#{1.day.ago.to_date}","#{Time.now.to_date}"]
    review_words = []
    review_sum = 0 #复习单词总数
    review_date.each do |date|
      d_arr = xml.get_elements("/user_words/old_words/_#{date}//word")
      review_words = (review_words<<d_arr).flatten
      review_sum += d_arr.length
    end
    recite_words = xml.get_elements("/user_words/new_words//word")
    recite_sum = recite_words.length #新学单词总数
    
    #XML中的单词数如果少于限制数，则补充新词
    if recite_sum<NEW_WORDS_SUM && review_sum+recite_sum<LIMIT_WORDS_SUM
      nw_sum = NEW_WORDS_SUM - recite_sum
      nomal_ids = record.nomal_ids.split(",")
      @new_words = nomal_ids[0,nw_sum]
      record.update_attribute("nomal_ids",nomal_ids[nw_sum..-1].join(","))
      p @new_words

    end



  end
  

end
