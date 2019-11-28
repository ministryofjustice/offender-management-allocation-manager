class MigrateOldVersionRecords < ActiveRecord::Migration[6.0]
  # This fixes the data problems (all allocation history vanishing)
  # caused by the AllocationVersion class rename
  def up
    PaperTrail::Version.where(item_type: 'AllocationVersion').
      update_all(item_type: 'Allocation')
  end

  def down

  end
end
