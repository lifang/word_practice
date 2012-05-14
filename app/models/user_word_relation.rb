# encoding: utf-8
class UserWordRelation < ActiveRecord::Base
  belongs_to :user

  require 'rexml/document'
  include REXML

  
  STATUS = {:NOMAL => 0, :RECITE => 1} #0 未背诵 1 已背诵

  def self.user_words(user_id, category_id)
    return UserWordRelation.count_by_sql(["select count(uwr.id) from user_word_relations uwr
      inner join words w on w.id = uwr.word_id
      where w.category_id = ? and uwr.status = #{STATUS[:NOMAL]} and uwr.user_id = ? ", category_id, user_id])
  end

  #打开用户正在背诵的词汇表
  def open_file
    file = File.open "#{Constant::PUBLIC_PATH}/user_word_xml/#{self.practice_url}"
    doc = Document.new(file)
    file.close
    return doc
  end

end
