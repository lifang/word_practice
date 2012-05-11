class WordsController < ApplicationController
  require 'rexml/document'
  include REXML
  def index
    cookies[:user_id]=1
    cookies[:user_name]="jeffrey6052"
    #---------------------------------------------------硬写 cookies
#    @user = User.find(cookies[:user_id])
#    @user.init_word_list(2)  # 用户第一次登录，创建数据库记录，以及XML文件
#    @user.makeup_words(cookies[:user_id])  # 根据xml内容更新数据库

    user_id = cookies[:user_id]
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
  

end
