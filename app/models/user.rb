#encoding: utf-8
class User < ActiveRecord::Base
  has_one :user_word_relation

  FROM = {"sina" => "新浪微博", "renren" => "人人网", "qq" => "腾讯网", "kaixin" => "开心网", "baidu" => "百度"}
  TIME_SORT = {:ASC => 0, :DESC => 1}   #用户列表按创建时间正序倒序排列
  U_FROM = {:WEB => 0, :APP => 1} #注册用户来源，0 网站   1 应用
  USER_FROM = {0 => "网站" , 1 => "应用"}

  DEFAULT_PASSWORD = "123456"

  #如果用户是第一次登录，则新建用户的背词列表
  def self.init_word_list(category_id)
    if self.user_word_relation.nil?
      phone_words = PhoneWord.find_by_sql("select id from phone_words order by level, rand()")
      word_ids = []
      word_ids = phone_words.collect { |item| item.id }
      practice_url = self.write_file(self.xml_content, Time.now.strftime("%Y_%m_%d"), "xml", "user_word_xml")
      UserWordRelation.create(:user_id => self.id, :nomal => word_ids.join(","), :category_id => category_id,
        :login_time => Time.now.to_datetime, :practice_url => practice_url)
    end
  end

  #根据用户更新用户当天要复习的单词
  def makeup_words(user_id)
    user_word_relation = UserWordRelation.find_by_sql(["select id, practice_url
      from user_word_relations where user_id = ?", user_id])
    unless user_word_relation.nil?
      
      
    end
  end

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

