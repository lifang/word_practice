#encoding: utf-8
class User < ActiveRecord::Base
  require 'rexml/document'
  include REXML
  
  has_one :user_word_relation
  
  REPEAT_STATUS = {"L" => 1 , "L1" => 2, "L2" => 3, "L3" => 4} #复习共四轮
  REPEAT_NUM = {1 => "L" , 2 => "L1", 3 => "L2", 4 => "L3"}
  REPEAT_DAY = {"L" => 1, "L1" => 2, "L2" => 4, "L3" => 8} #每一轮的复习间隔时间分别为：L 1天， L1 2天， L2 4天， L3 8天
  REPEAT_LAST_DAY = {"L" => 0, "L1" => 1, "L2" => 2, "L3" => 4} #每一轮的复习可以推迟的时间分别为：L 0天， L1 1天， L2 2天， L3 4天


  FROM = {"sina" => "新浪微博", "renren" => "人人网", "qq" => "腾讯网", "kaixin" => "开心网", "baidu" => "百度"}
  TIME_SORT = {:ASC => 0, :DESC => 1}   #用户列表按创建时间正序倒序排列
  U_FROM = {:WEB => 0, :APP => 1} #注册用户来源，0 网站   1 应用
  USER_FROM = {0 => "网站" , 1 => "应用"}


  #如果用户是第一次登录，则新建用户的背词列表
  def init_word_list(category_id)
    if self.user_word_relation.nil?
      phone_words = PhoneWord.find_by_sql("select id from phone_words order by level, rand()")
      word_ids = []
      word_ids = phone_words.collect { |item| item.id }
      practice_url = self.write_file(self.xml_content, Time.now.strftime("%Y_%m_%d"), "xml", "user_word_xml")
      UserWordRelation.create(:user_id => self.id, :nomal_ids => word_ids.join(","), :category_id => category_id,
        :login_time => Time.now.to_datetime, :practice_url => practice_url)
    end
  end

  #根据用户更新用户当天要复习的单词
  def makeup_oldwords(user_id)
    user_word_relation = UserWordRelation.find_by_sql(["select id, user_id, practice_url
      from user_word_relations where user_id = ?", user_id])[0]
    unless user_word_relation.nil?
      doc = user_word_relation.open_file
      all_dates = doc.root.elements["old_words"].elements["all_date"].text
      leave_dates = []
      all_dates.split(",").each {|d|
        leave_dates << d if d.to_date < Time.now.to_date
      } unless all_dates.nil? or all_dates.empty?
      
      leave_dates.each {|l_d|
        word_list = doc.root.elements["old_words"].elements["_#{l_d}"]
        if !word_list.nil? and word_list.elements.size > 0
          word_list.each_element {|w|
            if w.attributes["step"].to_i == REPEAT_STATUS["L"]
              doc.root.elements["new_words"].add_element("word",
                {"id"=>"#{w.attributes["id"]}", "is_error" => "false", "repeat_time" => "0"})
              doc.delete_element(w.xpath)
            else
              if w.attributes["end_at"].to_date < Time.now.to_date
                new_start_date = Time.now.strftime("%Y-%m-%d")
                current_date_element = doc.root.elements["old_words"].elements["_#{new_start_date}"]
                doc.root.elements["old_words"].add_element("_#{new_start_date}") if current_date_element.nil?
                end_date = (Time.now + REPEAT_LAST_DAY[REPEAT_NUM[w.attributes["step"].to_i]].days).strftime("%Y-%m-%d")
                
                doc.root.elements["old_words"].elements["_#{new_start_date}"].add_element("word",
                  {"step" => "#{w.attributes["step"].to_i - 1}", "start_at" => new_start_date, "end_at" => end_date,
                      "is_error" => "false", "repeat_time" => "0", "id" => w.attributes["id"]})
                doc.delete_element(w.xpath)
              end
            end
          }
        else
          doc.delete_element(word_list.xpath) unless word_list.nil?
          doc.root.elements["old_words"].elements["all_date"].text = (all_dates.split(",") - [l_d]).join(",")
        end
      } unless leave_dates.blank?
      path_url = user_word_relation.practice_url.split("/")

      puts doc
      user_word_relation.user.write_file(doc.to_s, path_url[1], "xml", "user_word_xml")
    end
  end

  #写文件
  def write_file(str, path, file_type, super_path)
    dir = "#{Rails.root}/public/#{super_path}"
    Dir.mkdir(dir) unless File.directory?(dir)
    unless File.directory?(dir + "/" + path)
      Dir.mkdir(dir + "/" + path)
    end
    file_name = "/" + path + "/#{self.id}." + file_type

    url = dir + file_name
    f=File.new(url,"w+")
    f.write("#{str.force_encoding('UTF-8')}")
    f.close
    return file_name
  end

  #创建xml文件
  def xml_content(options = {})
    content = <<-XML
      <?xml version='1.0' encoding='UTF-8'?>
      <user_words user_id='#{self.id}'>
        <new_words></new_words>
        <old_words></old_words>
      </user_words>
    XML
    return content
  end

  

end
