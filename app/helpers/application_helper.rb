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

end
