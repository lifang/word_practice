class PhoneWord < ActiveRecord::Base
  belongs_to :category
  has_many :word_sentences,:foreign_key=>:word_id

  WORD_TYPE = {"0"=>"n.","1"=>"v.","2"=>"pron.","3"=>"adj.","4"=>"adv.","5"=>"num.",
    "6"=>"art.","7"=>"prep.","8"=>"conj.","9"=>"interj.","10"=>"u = ","11"=>"c = ","12"=>"pl = ",nil=>""}


  def self.get_words_by_level(word_id, level, num)
    PhoneWord.find_by_sql(["select * from phone_words where id != ? and level = ? order by rand() limit ? ",
        word_id, level, num])
  end

end
