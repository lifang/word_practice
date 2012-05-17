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
  def update_newwords(xml,recite_sum,review_sum,user_id)
    new_words_node = xml.root.elements["new_words"]
    record = UserWordRelation.find_by_user_id(user_id)
    new_words_node.attributes["update"].nil? ? new_words_node.add_attribute("update", "#{Time.now.to_date}") : new_words_node.attributes["update"] = "#{Time.now.to_date}"
    if recite_sum<Constant::NEW_WORDS_SUM && review_sum+recite_sum<Constant::LIMIT_WORDS_SUM
      nw_sum = Constant::NEW_WORDS_SUM - recite_sum
      nomal_ids = record.nomal_ids.split(",")
      @new_words = nomal_ids[0,nw_sum]
      record.update_attribute("nomal_ids",nomal_ids[nw_sum..-1].nil? ? "" : nomal_ids[nw_sum..-1].join(","))
      @new_words.each do |word_id|
        word_node = new_words_node.add_element("word")
        word_node.add_attribute("id","#{word_id}")
        word_node.add_attribute("is_error","false")
        word_node.add_attribute("repeat_time","0")
      end
    end
    return xml
  end

  #处理新学的单词,error="error"表示用户题目做错
  def handle_recite_word(xml,word_id,error)
    old_words_node = xml.root.elements["old_words"]
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
    return xml
  end

end
