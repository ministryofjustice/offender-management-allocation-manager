class UpdateIndexOnAllocations < ActiveRecord::Migration[5.2]
  def up
    remove_index :allocations, :prison_offender_manager_id
    add_index :allocations, :nomis_staff_id
  end

  def down
    remove_index :allocations, :nomis_staff_id
    add_index :allocations, :prison_offender_manager_id
  end
end
