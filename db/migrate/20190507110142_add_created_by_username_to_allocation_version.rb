class AddCreatedByUsernameToAllocationVersion < ActiveRecord::Migration[5.2]
  def up
    add_column :allocation_versions, :created_by_username, :string
  end

  def down
    remove_column :allocation_versions, :created_by_username
  end
end
