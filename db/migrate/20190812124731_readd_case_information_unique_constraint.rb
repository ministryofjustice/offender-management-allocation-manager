class ReaddCaseInformationUniqueConstraint < ActiveRecord::Migration[5.2]
  def up
    remove_index :case_information, :nomis_offender_id
    add_index :case_information, :nomis_offender_id, unique: true
  end

  def down
    remove_index :case_information, :nomis_offender_id
    add_index :case_information, :nomis_offender_id
  end
end
