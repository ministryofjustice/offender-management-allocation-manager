class AddUniqueConstraintToDeliusCrn < ActiveRecord::Migration[5.2]
  def up
    remove_index :delius_data, :noms_no
    add_index :delius_data, [:crn], :unique => true
  end
  def down
    remove_index :delius_data, :crn
    add_index :delius_data, [:noms_no], :unique => true
  end
end
