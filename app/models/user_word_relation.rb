# encoding: utf-8
class UserWordRelation < ActiveRecord::Base
  belongs_to :user

  require 'rexml/document'
  include REXML

  
  STUDY_ROLE = {:NOMAL => 0, :SPELL => 1} #0 认读 1 认读 + 拼写


  def self.user_words(user_id, category_id)
    return UserWordRelation.count_by_sql(["select count(uwr.id) from user_word_relations uwr
      inner join words w on w.id = uwr.word_id
      where w.category_id = ? and uwr.status = #{STATUS[:NOMAL]} and uwr.user_id = ? ", category_id, user_id])
  end

  #打开用户正在背诵的词汇表
  def open_file
    file = File.open "#{Constant::PUBLIC_PATH}#{self.practice_url}"
    doc = Document.new(file)
    file.close
    return doc
  end

  #更新用户的学习时间
  def update_study_times(num)
    self.update_attributes(:all_study_time => self.all_study_time + num)
  end

end
