class DropCalculatedEarlyAllocationStatus < ActiveRecord::Migration[8.1]
  def up
    drop_table :calculated_early_allocation_statuses, if_exists: true
  end

  def down
    create_table :calculated_early_allocation_statuses, id: false do |t|
      t.string :nomis_offender_id, primary_key: true
      t.boolean :eligible, null: false
      t.timestamps
    end
  end
end
