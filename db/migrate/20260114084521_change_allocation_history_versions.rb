class ChangeAllocationHistoryVersions < ActiveRecord::Migration[8.1]
  def change
    remove_foreign_key(:allocation_history_versions, to_table: :allocation_history, index: true, null: false)
  end
end
