class AddMappaLevelToCaseInformation < ActiveRecord::Migration[5.2]
  def change
    change_table :case_information do |t|
      # valid mappa levels are 1,2,3,blank
      t.integer :mappa_level, null: true
    end
  end
end
