class AddComNameField < ActiveRecord::Migration[5.2]
  def up
    add_column :allocation_versions, :com_name, :string
  end

  def down
    remove_column :allocation_versions, :com_name
  end
end
