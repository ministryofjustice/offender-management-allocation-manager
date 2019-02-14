class CreateCaseInformation < ActiveRecord::Migration[5.2]
  def change
    create_table :case_information do |t|
      t.string :tier
      t.string :case_allocation
      t.string :nomis_offender_id
    end
  end
end
