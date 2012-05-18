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
          {"id"=>"#{word_id}", "is_error" => "false", "repeat_time" => "0", "step" => "0"})
      end
    end
    return xml
  end

  #处理新学的单词,error="error"表示用户题目做错
  def handle_recite_word(xml,word_id,error)
    old_words_node = xml.root.elements["old_words"]
    word_node = xml.root.elements["new_words//word[@id='#{word_id}']"]
    this_step = word_node.attributes["step"].to_i
    if error == "error"
      insert_node = xml.root.elements["new_words"]
      new_word_node = insert_node.add_element("word")
      manage_element(new_word_node, {}, {:id=>word_id,:is_error=>"true",:repeat_time=>"0",:step=>this_step})
    else
      if word_node.attributes["is_error"]=="true" && word_node.attributes["repeat_time"]=="0"
        insert_node = xml.root.elements["new_words"]
        new_word_node = insert_node.add_element("word")
        manage_element(new_word_node, {}, {:id=>word_id,:is_error=>"true",:repeat_time=>word_node.attributes["repeat_time"].to_i+1,:step=>this_step})
      else
        if this_step<4
          insert_node = xml.root.elements["new_words"]
          new_word_node = insert_node.add_element("word")
          manage_element(new_word_node, {}, {:id=>word_id,:is_error=>"false",:repeat_time=>0,:step=>this_step+1})
        else
          insert_node = old_words_node.elements["_#{Constant::REVIEW_STEP[0][0].day.since.to_date}"]
          insert_node = old_words_node.add_element("_#{Constant::REVIEW_STEP[0][0].day.since.to_date}") unless insert_node
          new_word_node = insert_node.add_element("word")
          manage_element(new_word_node, {}, {:id=>word_id,:step=>1,:start_at=>Constant::REVIEW_STEP[0][0].day.since.to_date,:end_at=>(Constant::REVIEW_STEP[0][0]+Constant::REVIEW_STEP[0][1]).day.since.to_date,:is_error=>"false",:repeat_time=>"0"})
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
    if error == "error"
      insert_node = xml.root.elements["_#{Time.now.to_date}"]
      insert_node = old_words_node.add_element("_#{Time.now.to_date}") unless insert_node
      new_word_node = insert_node.add_element("word")
      manage_element(new_word_node, {}, {:id=>word_id,:start_at=>word_node.attributes["start_at"],:end_at=>word_node.attributes["end_at"],:step=>word_node.attributes["step"],:is_error=>"true",:repeat_time=>"0"})
    else
      if word_node.attributes["is_error"]=="true" && word_node.attributes["repeat_time"].to_i<1
        insert_node = old_words_node.elements["_#{Time.now.to_date}"]
        insert_node = old_words_node.add_element("_#{Time.now.to_date}") unless insert_node
        new_word_node = insert_node.add_element("word")
        manage_element(new_word_node, {}, {:id=>word_id,:start_at=>word_node.attributes["start_at"],:end_at=>word_node.attributes["end_at"],:step=>word_node.attributes["step"],:is_error=>"true",:repeat_time=>word_node.attributes["repeat_time"].to_i+1})
      else
        this_step = word_node.attributes["step"].to_i
        if this_step<4
          insert_node = old_words_node.elements["_#{Constant::REVIEW_STEP[this_step][0].day.since.to_date}"]
          insert_node = old_words_node.add_element("_#{Constant::REVIEW_STEP[this_step][0].day.since.to_date}") unless insert_node
          new_word_node = insert_node.add_element("word")
          manage_element(new_word_node, {}, {:id=>word_id,:step=>this_step+1,:start_at=>Constant::REVIEW_STEP[this_step][0].day.since.to_date,:end_at=>(Constant::REVIEW_STEP[this_step][0]+Constant::REVIEW_STEP[this_step][1]).day.since.to_date,:is_error=>"false",:repeat_time=>"0"})
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
    sentences = word.word_sentences
    #获取干扰选项
    other_words = PhoneWord.get_words_by_level(word.level, 10)
    return {:word=>word,:web_type=>web_type,:sentences=>sentences,:other_words=>(other_words.sort_by{rand})[0,3],:step=>step}
  end

end
