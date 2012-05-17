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
    #XML中的单词数如果少于限制数，则补充新词,一天最多更新一次
    last_update = xml.root.elements["new_words"].attributes["update"]
    if last_update.nil? || last_update.to_date.nil? || last_update.to_date<Time.now.to_date
      xml = update_newwords(xml,@recite_sum,@review_sum,cookies[:user_id])
      write_xml(xml,x_url)
      redirect_to "/words/start"
      return false
    end
    #当前背诵的单词,review_words的第一个，没有则选new_words第一个,全没有，则表示当天单词背诵完成
    if @review_sum > 0
      @xml_word,@web_type = @review_words[0],"review"
    else
      if @recite_sum > 0
        @xml_word,@web_type = @recite_words[0],"recite"
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
    xml = handle_recite_word(xml,word_id,error) if type=="recite"   #处理新背的单词
    xml = handle_review_word(xml,word_id,error) if type=="review"   #处理复习的单词
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
