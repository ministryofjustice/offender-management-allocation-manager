class AddUserAndPrisonToVersions < ActiveRecord::Migration[6.0]
  def change
    change_table :versions do |t|
      t.string :user_first_name
      t.string :user_last_name
      t.string :prison
    end
  end
end
