class RenameAllocationToAllocationHistory < ActiveRecord::Migration[6.0]
  def change
    rename_table :allocations, :allocation_history

    reversible do |dir|
      dir.up do
        # Rename PaperTrail versions to use the new model name
        PaperTrail::Version.where(item_type: 'Allocation').update_all(item_type: 'AllocationHistory')
      end
      dir.down do
        # Revert PaperTrail versions to use the old model name
        PaperTrail::Version.where(item_type: 'AllocationHistory').update_all(item_type: 'Allocation')
      end
    end
  end
end
