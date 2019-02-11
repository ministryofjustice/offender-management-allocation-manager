class RenameColumnAllocationsTable < ActiveRecord::Migration[5.2]
  def up
    rename_column :allocations, :reason, :override_reason
    rename_column :allocations, :note, :override_detail
  end

  def down
    rename_column :allocations, :override_detail, :note
    rename_column :allocations, :override_reason, :reason
  end
end
