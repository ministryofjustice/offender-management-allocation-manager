class AddTimestampsToCaseInformation < ActiveRecord::Migration[5.2]
  def change
    change_table :case_information do |t|
      t.timestamps null: true
    end
  end
end
