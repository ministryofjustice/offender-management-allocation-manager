class AddIndexToCaseInformation < ActiveRecord::Migration[5.2]
  def up
    add_index :case_information, :nomis_offender_id
  end

  def down
    remove_index :case_information, :nomis_offender_id
  end
end
