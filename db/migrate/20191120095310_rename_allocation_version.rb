class RenameAllocationVersion < ActiveRecord::Migration[6.0]
  def up
    rename_table :allocation_versions, :allocations
  end

  def down
    rename_table :allocations, :allocation_versions
  end
end
