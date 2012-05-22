#encoding: utf-8
class User < ActiveRecord::Base
  require 'rexml/document'
  include REXML
  
  has_one :user_word_relation
  NEW_WORD_STEP = [1, 2, 3, 4]  #新单词的步骤, 共有4步
  OLD_WORD_TIME = [1, 2, 3, 4]  #复习的单词的轮次，共有4轮


  REPEAT_STATUS = {"L" => 1 , "L1" => 2, "L2" => 3, "L3" => 4} #复习共四轮
  REPEAT_NUM = {1 => "L" , 2 => "L1", 3 => "L2", 4 => "L3"}
  REPEAT_DAY = {"L" => 1, "L1" => 2, "L2" => 4, "L3" => 8} #每一轮的复习间隔时间分别为：L 1天， L1 2天， L2 4天， L3 8天
  REPEAT_LAST_DAY = {"L" => 0, "L1" => 1, "L2" => 2, "L3" => 4} #每一轮的复习可以推迟的时间分别为：L 0天， L1 1天， L2 2天， L3 4天

  DEFAULT_TIMER = "15, 3"  #默认的答题时间和继续的时间


  #如果用户是第一次登录，则新建用户的背词列表
  def init_word_list(category_id)
    user_word=self.user_word_relation
    if user_word.nil?
      phone_words = PhoneWord.find_by_sql("select id from phone_words order by level, rand()")
      word_ids = []
      word_ids = phone_words.collect { |item| item.id }
      practice_url = self.write_file(self.xml_content, Time.now.strftime("%Y_%m_%d"), "xml", "user_word_xml")
      user_word = UserWordRelation.create(:user_id => self.id, :nomal_ids => word_ids.join(","), :category_id => category_id,
        :login_time => Time.now.to_datetime, :practice_url => practice_url, :timer => DEFAULT_TIMER)
    end
    return user_word
  end

  #根据用户更新用户当天要复习的单词
  def makeup_oldwords(user_id)
    user_word_relation = UserWordRelation.find_by_sql(["select id, user_id, practice_url
      from user_word_relations where user_id = ?", user_id])[0]
    unless user_word_relation.nil?
      doc = user_word_relation.open_file
      recite_words = doc.get_elements("/user_words/new_words//word")
      recite_words.each do |e|
        e.add_attribute("step", "#{NEW_WORD_STEP[0]}")
      end
      all_dates = doc.root.elements["old_words"].elements["all_date"].text if doc.root.elements["old_words"].elements["all_date"]
      leave_dates = []
      all_dates.split(",").each {|d|
        leave_dates << d if d.to_date < Time.now.to_date
      } unless all_dates.nil? or all_dates.empty?
      
      leave_dates.each {|l_d|
        word_list = doc.root.elements["old_words"].elements["_#{l_d}"]
        if !word_list.nil? and word_list.elements.size > 0
          word_list.each_element {|w|
            if w.attributes["step"].to_i == OLD_WORD_TIME[0]
              doc.root.elements["new_words"].add_element("word",
                {"id"=>"#{w.attributes["id"]}", "is_error" => "false", "repeat_time" => "0", "step" => "0"})
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
      user_word_relation.user.write_file(doc.to_s, path_url[2], "xml", "user_word_xml")
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
    return "/#{super_path}" + file_name
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


  #返回 [已掌握 初步掌握 未掌握],如 [35,35,30],3个元素相加等于100
  def circle_data
    result = {}
    record = UserWordRelation.find_by_user_id(self.id)
    nomal_ids = record.nomal_ids.nil? ? [] : record.nomal_ids.split(",")
    nomal_sum = nomal_ids.length
    recite_ids = record.recite_ids.nil? ? [] : record.recite_ids.split(",")
    recite_sum = recite_ids.length
    xml_file = File.open("#{Rails.root}/public#{record.practice_url}")
    xml = Document.new(xml_file)
    xml_file.close
    new_sum = xml.get_elements("/user_words/new_words//word").length
    doing_sum = xml.get_elements("/user_words/old_words//word").length
    all_sum = recite_sum + doing_sum + new_sum + nomal_sum
    circle = [recite_sum*100/all_sum , doing_sum*100/all_sum]
    circle[2] = 100 - circle[0] - circle[1]
    result[:data] = [recite_sum,doing_sum,nomal_sum+new_sum]
    result[:circle] = circle
    return result
  end

  

end

