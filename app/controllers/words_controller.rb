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
    @circle_data = @user.circle_data
  end

  
  def show
      
  end


  #开始学习
  def start
    
    #统计当天需要背诵的单词
    record = UserWordRelation.find_by_user_id(cookies[:user_id])
    x_url = "#{Rails.root}/public/user_word_xml/#{record.practice_url}"
    xml = get_doc(x_url)
    review_date = 8.step(0,-1).to_a.collect{|i|i=i.day.ago.to_date}
    @review_words = []
    @review_sum = 0 #复习单词总数
    review_date.each do |date|
      d_arr = xml.get_elements("/user_words/old_words/_#{date}//word")
      @review_words = (@review_words<<d_arr).flatten
      @review_sum += d_arr.length
    end
    @recite_words = xml.get_elements("/user_words/new_words//word")
    @recite_sum = @recite_words.length #新学单词总数
    @update = xml.root.elements["new_words"].attributes["update"]

    #XML中的单词数如果少于限制数，则补充新词,一天最多更新一次
    if @update.nil? || @update.to_date.nil? || @update.to_date<Time.now.to_date
      @update.nil? ? xml.root.elements["new_words"].add_attribute("update", "#{Time.now.to_date}") : @update = "#{Time.now.to_date}"
      puts @update
      if @recite_sum<NEW_WORDS_SUM && @review_sum+@recite_sum<LIMIT_WORDS_SUM
        nw_sum = NEW_WORDS_SUM - @recite_sum
        nomal_ids = record.nomal_ids.split(",")
        @new_words = nomal_ids[0,nw_sum]
        record.update_attribute("nomal_ids",nomal_ids[nw_sum..-1].join(","))
        new_words_node = xml.root.elements["new_words"]
        @new_words.each do |word_id|
          word_node = new_words_node.add_element("word")
          word_node.add_attribute("id","#{word_id}")
          word_node.add_attribute("is_error","false")
          word_node.add_attribute("repeat_time","0")
        end
      end
      write_xml(xml,x_url)
    end
    
    #当前背诵的单词,review_words的第一个，没有则选new_words第一个,全没有，则表示当天单词背诵完成
    if @review_sum > 0
      @xml_word = @review_words[0]
      @web_type = "review"
    else
      if @recite_sum > 0
        @xml_word = @recite_words[0]
        @web_type = "recite"
      else
        render :inline=>"当天的单词已经全部背诵完，Congratulation :)"
        return false
      end
    end
    @word = PhoneWord.find(@xml_word.attributes["id"])
    @sentences = @word.word_sentences
    #获取干扰选项
    @other_words = []
    (1..200).to_a.shuffle.each do |i|
      break if @other_words.length>=3
      next if PhoneWord.find(i).nil? || i==@word.id
      @other_words << PhoneWord.find(i)
    end
  end


  #继续学习
  def next_word
    #to be continue
    type = params[:type]
    word_id = params[:word_id]
    error = params[:error]
    record = UserWordRelation.find_by_user_id(cookies[:user_id])
    x_url = "#{Rails.root}/public/user_word_xml/#{record.practice_url}"
    xml = get_doc(x_url)
    old_words_node = xml.root.elements["old_words"]

    
    #新单词
    if type=="recite"
      word_node = xml.root.elements["new_words//word[@id='#{word_id}']"]
      if error == "error"
        insert_node = xml.root.elements["new_words"]
        new_word_node = insert_node.add_element("word")
        manage_element(new_word_node, {}, {:id=>word_id,:is_error=>"true",:repeat_time=>"0"})
      else
        if word_node.attributes["is_error"]=="true" && word_node.attributes["repeat_time"].to_i<1
          insert_node = xml.root.elements["new_words"]
          new_word_node = insert_node.add_element("word")
          manage_element(new_word_node, {}, {:id=>word_id,:is_error=>"true",:repeat_time=>word_node.attributes["repeat_time"].to_i+1})
        else
          insert_node = old_words_node.elements["_#{Constant::REVIEW_STEP[0][0].day.since.to_date}"]
          insert_node = old_words_node.add_element("_#{Constant::REVIEW_STEP[0][0].day.since.to_date}") unless insert_node
          new_word_node = insert_node.add_element("word")
          manage_element(new_word_node, {}, {:id=>word_id,:step=>1,:start_at=>Constant::REVIEW_STEP[0][0].day.since.to_date,:end_at=>(Constant::REVIEW_STEP[0][0]+Constant::REVIEW_STEP[0][1]).day.since.to_date,:is_error=>"false",:repeat_time=>"0"})
        end
      end
      xml.delete_element(word_node.xpath)
    end


    #复习单词
    if type=="review"
      word_node = xml.root.elements["old_words//word[@id='#{word_id}']"]
      if error == "error"
        insert_node = xml.root.elements["_#{Time.now.to_date}"]
        insert_node = old_words_node.add_element("_#{Time.now.to_date}") unless insert_node
        new_word_node = insert_node.add_element("word")
        manage_element(new_word_node, {}, {:id=>word_id,:start_at=>word_node.attributes["start_at"],:end_at=>word_node.attributes["end_at"],:step=>word_node.attributes["step"],:is_error=>"true",:repeat_time=>"0"})
      else
        if word_node.attributes["is_error"]=="true" && word_node.attributes["repeat_time"].to_i<1
          insert_node = xml.root.elements["_#{Time.now.to_date}"]
          insert_node = old_words_node.add_element("_#{Time.now.to_date}") unless insert_node
          new_word_node = insert_node.add_element("word")
          manage_element(new_word_node, {}, {:id=>word_id,:start_at=>word_node.attributes["start_at"],:end_at=>word_node.attributes["end_at"],:step=>word_node.attributes["step"],:is_error=>"true",:repeat_time=>word_node.attributes["repeat_time"].to_i+1})
        else
          this_step = word_node.attributes["step"].to_i
          insert_node = old_words_node.elements["_#{Constant::REVIEW_STEP[this_step][0].day.since.to_date}"]
          insert_node = old_words_node.add_element("_#{Constant::REVIEW_STEP[this_step][0].day.since.to_date}") unless insert_node
          new_word_node = insert_node.add_element("word")
          manage_element(new_word_node, {}, {:id=>word_id,:step=>this_step+1,:start_at=>Constant::REVIEW_STEP[this_step][0].day.since.to_date,:end_at=>(Constant::REVIEW_STEP[this_step][0]+Constant::REVIEW_STEP[this_step][1]).day.since.to_date,:is_error=>"false",:repeat_time=>"0"})
        end
      end
      xml.delete_element(word_node.xpath)
    end


    write_xml(xml,x_url)
    redirect_to "/words/start"
  end

  #已经掌握
  def know_well
    #to be continue
    word_id = params[:word_id]
    record = UserWordRelation.find_by_user_id(cookies[:user_id])
    x_url = "#{Rails.root}/public/user_word_xml/#{record.practice_url}"
    xml = get_doc(x_url)
    word_node = xml.root.elements["new_words//word[@id='#{word_id}']"]
    word_node = xml.root.elements["old_words//word[@id='#{word_id}']"] unless word_node
    xml.delete_element(word_node.xpath)
    write_xml(xml,x_url)
    recite_ids = record.recite_ids.nil? ? "" : record.recite_ids
    recite_ids = (recite_ids.split(",")<<word_id).join(",")
    record.update_attribute("recite_ids",recite_ids)
    redirect_to "/words/start"
  end
  

end
