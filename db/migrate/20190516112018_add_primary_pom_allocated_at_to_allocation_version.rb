class AddPrimaryPomAllocatedAtToAllocationVersion < ActiveRecord::Migration[5.2]
  def up
    add_column :allocation_versions, :primary_pom_allocated_at, :datetime
  end

  def down
    remove_column :allocation_versions, :primary_pom_allocated_at
  end
end
