class AddTimestampToEmailHistory < ActiveRecord::Migration[6.0]
  def change
    change_table :email_histories do |t|
      t.timestamps null: false
    end
  end
end
