class CreatePhoneWords < ActiveRecord::Migration
  def change
    create_table :phone_words do |t|

      t.timestamps
    end
  end
end
