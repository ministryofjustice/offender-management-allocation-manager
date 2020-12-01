class AllocationsEnforcedToBeUnique < ActiveRecord::Migration[6.0]
  def change
    change_table :allocation_history do |t|
      t.remove_index :nomis_offender_id
      t.index :nomis_offender_id, unique: true
    end
  end
end
