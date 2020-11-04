class RemoveOldModelTables < ActiveRecord::Migration[6.0]
  def change
    drop_table :delius_data
    drop_table :tier_changes
  end
end
