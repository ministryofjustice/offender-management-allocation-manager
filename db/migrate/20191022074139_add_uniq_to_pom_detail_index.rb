class AddUniqToPomDetailIndex < ActiveRecord::Migration[5.2]
  def up
    remove_index :pom_details, :nomis_staff_id
    add_index :pom_details, :nomis_staff_id, unique: true
  end

  def down
    remove_index :pom_details, :nomis_staff_id, unique: true
    add_index :case_information, :nomis_offender_id
  end
end