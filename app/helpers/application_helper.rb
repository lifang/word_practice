#encoding: utf-8
module ApplicationHelper
  require 'rexml/document'
  include REXML

  # START -------XML文件操作--------require 'rexml/document'----------include REXML----------
  #将XML文件生成document对象
  def get_doc(url)
    file = File.new(url)
    doc = Document.new(file).root
    file.close
    return doc
  end

  #处理XML节点
  #参数解释： element为doc.elements[xpath]产生的对象，content为子内容，attributes为属性
  def manage_element(element, content={}, attributes={})
    content.each do |key, value|
      arr, ele = "#{key}".split("/"), element
      arr.each do |a|
        ele = ele.elements[a].nil? ? ele.add_element(a) : ele.elements[a]
      end
      ele.text.nil? ? ele.add_text("#{value}") : ele.text="#{value}"
    end
    attributes.each do |key, value|
      element.attributes["#{key}"].nil? ? element.add_attribute("#{key}", "#{value}") : element.attributes["#{key}"] = "#{value}"
    end
    return element
  end

  #将document对象生成xml文件
  def write_xml(doc, url)
    file = File.new(url, File::CREAT|File::TRUNC|File::RDWR, 0644)
    file.write(doc.to_s)
    file.close
  end

  # END -------XML文件操作----------


  #xml载入新单词
  def update_newwords(xml,user_id)
    review_date = 8.step(0,-1).to_a.collect{|i|i=i.day.ago.to_date}
    review_sum = 0 #复习单词总数
    review_date.each do |date|
      d_arr = xml.get_elements("/user_words/old_words/_#{date}//word")
      review_sum += d_arr.length
    end
    recite_words = xml.get_elements("/user_words/new_words//word")
    recite_sum = recite_words.length #新学单词总数
    new_words_node = xml.root.elements["new_words"]
    record = UserWordRelation.find_by_user_id(user_id)
    #new_words_node.attributes["update"].nil? ? new_words_node.add_attribute("update", "#{Time.now.to_date}") : new_words_node.attributes["update"] = "#{Time.now.to_date}"
    if recite_sum<Constant::NEW_WORDS_SUM && review_sum+recite_sum<Constant::LIMIT_WORDS_SUM
      nw_sum = Constant::NEW_WORDS_SUM - recite_sum
      nomal_ids = record.nomal_ids.split(",")
      new_words = nomal_ids[0,nw_sum]
      record.update_attribute("nomal_ids",nomal_ids[nw_sum..-1].nil? ? "" : nomal_ids[nw_sum..-1].join(","))
      new_words.each do |word_id|
        new_words_node.add_element("word",
          {"id"=>"#{word_id}", "is_error" => "false", "repeat_time" => "0", "step" => "#{User::OLD_WORD_TIME[0]}"})
      end
    end
    return xml
  end

  #处理新学的单词,error="error"表示用户题目做错
  def handle_recite_word(xml,word_id,error)
    old_words_node = xml.root.elements["old_words"]
    word_node = xml.root.elements["new_words//word[@id='#{word_id}']"]
    this_step = word_node.attributes["step"].to_i
    if error == "error"||error == "pass"
      if error == "error"
        insert_node = xml.root.elements["new_words"]
        insert_node.add_element("word", {"id" => word_id, "is_error" => "true",
            "repeat_time" => "0", "step" => this_step})
      elsif error == "pass"
        insert_node = xml.root.elements["new_words"]
        insert_node.add_element("word", {"id" => word_id, "is_error" => word_node.attributes["is_error"],
            "repeat_time" => word_node.attributes["repeat_time"], "step" => this_step})
      end
    else
      if word_node.attributes["is_error"]=="true" && word_node.attributes["repeat_time"]=="0"
        insert_node = xml.root.elements["new_words"]
        insert_node.add_element("word", {"id"=>word_id,"is_error"=>"true",
            "repeat_time"=>word_node.attributes["repeat_time"].to_i+1,"step"=>this_step})
      else
        if this_step<4
          insert_node = xml.root.elements["new_words"]
          insert_node.add_element("word", {"id"=>word_id,"is_error"=>"false","repeat_time"=>0,"step"=>this_step+1})
        else
          insert_node = old_words_node.elements["_#{Constant::REVIEW_STEP[0][0].day.since.to_date}"]
          insert_node = old_words_node.add_element("_#{Constant::REVIEW_STEP[0][0].day.since.to_date}") unless insert_node
          insert_node.add_element("word", {"id"=>word_id,"step"=>"#{User::OLD_WORD_TIME[0]}",
              "start_at"=>Constant::REVIEW_STEP[0][0].day.since.to_date,
              "end_at"=>(Constant::REVIEW_STEP[0][0]+Constant::REVIEW_STEP[0][1]).day.since.to_date,
              "is_error"=>"false","repeat_time"=>"0"})
          dates_str = xml.root.elements["old_words"].elements["all_date"].text if xml.root.elements["old_words"].elements["all_date"]
          dates_arr = (dates_str.nil? or dates_str.empty?) ? [] : dates_str.split(",")
          xml.root.elements["old_words"].elements["all_date"].text = (dates_arr|[Constant::REVIEW_STEP[0][0].day.since.to_date]).join(",")
        end
      end
    end
    xml.delete_element(word_node.xpath)
    return xml
  end

  #处理复习的单词,error="error"表示用户题目做错
  def handle_review_word(xml,word_id,error)
    old_words_node = xml.root.elements["old_words"]
    word_node = xml.root.elements["old_words//word[@id='#{word_id}']"]
    if error == "error"||error == "pass"
      if error == "error"
        insert_node = xml.root.elements["_#{Time.now.to_date}"]
        insert_node = old_words_node.add_element("_#{Time.now.to_date}") unless insert_node
        insert_node.add_element("word", {"id" => word_id, "start_at" => word_node.attributes["start_at"],
            "end_at" => word_node.attributes["end_at"],"step" => word_node.attributes["step"],"is_error" => "true","repeat_time" => "0"})
      elsif error == "pass"
        insert_node = xml.root.elements["_#{Time.now.to_date}"]
        insert_node = old_words_node.add_element("_#{Time.now.to_date}") unless insert_node
        insert_node.add_element("word", {"id" => word_id, "start_at" => word_node.attributes["start_at"],
            "end_at" => word_node.attributes["end_at"],"step" => word_node.attributes["step"],"is_error" => word_node.attributes["is_error"],"repeat_time" => word_node.attributes["repeat_time"]})
      end
    else
      if word_node.attributes["is_error"]=="true" && word_node.attributes["repeat_time"].to_i<1
        insert_node = old_words_node.elements["_#{Time.now.to_date}"]
        insert_node = old_words_node.add_element("_#{Time.now.to_date}") unless insert_node
        insert_node.add_element("word", {"id" => word_id, "start_at" => word_node.attributes["start_at"],
            "end_at" => word_node.attributes["end_at"], "step" => word_node.attributes["step"], "is_error" => "true",
            "repeat_time" => word_node.attributes["repeat_time"].to_i+1})
      else
        this_step = word_node.attributes["step"].to_i
        if this_step < User::OLD_WORD_TIME[3]
          insert_node = old_words_node.elements["_#{Constant::REVIEW_STEP[this_step][0].day.since.to_date}"]
          insert_node = old_words_node.add_element("_#{Constant::REVIEW_STEP[this_step][0].day.since.to_date}") unless insert_node
          insert_node.add_element("word", {"id" => word_id, "step" => this_step+1,
              "start_at" => Constant::REVIEW_STEP[this_step][0].day.since.to_date,
              "end_at" => (Constant::REVIEW_STEP[this_step][0]+Constant::REVIEW_STEP[this_step][1]).day.since.to_date,
              "is_error" => "false","repeat_time" => "0"})
          dates_str = xml.root.elements["old_words"].elements["all_date"].text if xml.root.elements["old_words"].elements["all_date"]
          dates_arr = (dates_str.nil? or dates_str.empty?) ? [] : dates_str.split(",")
          xml.root.elements["old_words"].elements["all_date"].text = (dates_arr|[Constant::REVIEW_STEP[this_step][0].day.since.to_date]).join(",")
        else
          record = UserWordRelation.find_by_user_id(cookies[:user_id])
          recite_ids = record.recite_ids.nil? ? "" : record.recite_ids
          recite_ids = (recite_ids.split(",")<<word_id).join(",")
          record.update_attribute("recite_ids",recite_ids)
        end
      end
    end
    xml.delete_element(word_node.xpath)
    return xml
  end

  #背词页面所需要的数据
  def word_source(xml)
    review_date = 8.step(0,-1).to_a.collect{|i|i=i.day.ago.to_date}
    review_words = []
    review_sum = 0 #复习单词总数
    review_date.each do |date|
      d_arr = xml.get_elements("/user_words/old_words/_#{date}//word")
      review_words = (review_words<<d_arr).flatten
      review_sum += d_arr.length
    end
    recite_words = xml.get_elements("/user_words/new_words//word")
    recite_sum = recite_words.length #新学单词总数

    #当前背诵的单词,review_words的第一个，没有则选new_words第一个,全没有，则表示当天单词背诵完成
    if review_sum > 0
      xml_word,web_type = review_words[0],"review"
    else
      if recite_sum > 0
        xml_word,web_type = recite_words[0],"recite"
      else
        return nil
      end
    end
    word = PhoneWord.find(xml_word.attributes["id"])
    step = xml_word.attributes["step"]
    is_error = xml_word.attributes["is_error"]
    sentences = word.word_sentences
    #获取干扰选项
    other_words = PhoneWord.get_words_by_level(word.id, word.level, 10)
    return {:word => word, :web_type => web_type, :sentences => sentences,
      :other_words => (other_words.sort_by{rand})[0,3], :step => step, :is_error => is_error}
  end

  #整理需要替换的单词
  def leving_word(sentence, word)
    lev_word = case
    when sentence =~/#{word}/
      word
    when sentence =~/#{word.capitalize}/
      word
    when sentence =~/#{word[0, word.length-1]}/
      word[0, word.length-1]
    when sentence =~/#{word[0, word.length-2]}/
      word[0, word.length-2]
    else word
    end
    return lev_word
  end

  def read_txt(file,serial)
    file = File.open("#{Rails.root}/public/#{file}/#{serial}.txt","rb")
    content= file.read.to_s
    file.close
    return content
  end

  def select_file(user_id)
    files=read_txt("users_action",user_id)
    if files.include? "0"
      all_file=files.split(";")
      unread_files=all_file[0].split(",")
      unread_files.delete("0")
      num=unread_files[rand(unread_files.size-1)]
      select_file=num
      unread_files.delete(select_file)
      select_file="#{select_file},"+all_file[1] unless all_file[1].nil?
      url="#{Rails.root}/public/users_action/#{1}.txt"
      if unread_files==[]
        write_xml(select_file,url)
      else
        str=(unread_files << 0).join(",")+";#{select_file}"
        write_xml(str,url)
      end
    end
    return num
  end

end
