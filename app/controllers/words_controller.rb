class WordsController < ApplicationController
  require 'rexml/document'
  include REXML
  def index
    cookies[:user_id]=1
    cookies[:user_name]="jeffrey6052"
    #---------------------------------------------------硬写 cookies
    @user = User.find(cookies[:user_id])
#    @user.init_word_list(2)  # 用户第一次登录，创建数据库记录，以及XML文件
    @user.makeup_words(cookies[:user_id])  # 根据xml内容更新数据库
    
    @record = UserWordRelation.find_by_user_id(cookies[:user_id])
    xml_file = File.open("#{Rails.root}/public/user_word_xml/#{@record.practice_url}")
    @xml = Document.new(xml_file)
    xml_file.close
    puts @xml
  end

  def show
  end

end
