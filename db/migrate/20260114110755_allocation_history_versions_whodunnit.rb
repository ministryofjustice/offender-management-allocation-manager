class AllocationHistoryVersionsWhodunnit < ActiveRecord::Migration[8.1]
  def change
    rename_column :allocation_history_versions, :created_by_username, :whodunnit
  end
end
