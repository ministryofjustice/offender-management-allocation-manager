class MakeCaseInformationNomisIdUnique < ActiveRecord::Migration[5.2]
  # prevent race conditions on creating CaseInformation records
  def up
    # remove_index :case_information, :nomis_offender_id
    # add_index :case_information, :nomis_offender_id, unique: true
  end

  def down
    # remove_index :case_information, :nomis_offender_id
    # add_index :case_information, :nomis_offender_id
  end
end
