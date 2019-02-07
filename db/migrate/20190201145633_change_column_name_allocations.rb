class ChangeColumnNameAllocations < ActiveRecord::Migration[5.2]
  def up
    rename_column :allocations, :staff_id, :prison_offender_manager_id
  end

  def down
    rename_column :allocations, :prison_offender_manager_id, :staff_id
  end
end
