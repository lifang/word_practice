class PhoneWord < ActiveRecord::Base
  belongs_to :category
  has_many :word_sentences

  
end
