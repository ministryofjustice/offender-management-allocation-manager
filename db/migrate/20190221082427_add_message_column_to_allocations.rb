class AddMessageColumnToAllocations < ActiveRecord::Migration[5.2]
  def up
    add_column :allocations, :message, :text
  end

  def down
    remove_column :allocations, :message
  end
end
