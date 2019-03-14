class AddReponsibilityColumnToAllocations < ActiveRecord::Migration[5.2]
  def up
    add_column :allocations, :responsibility, :text
  end

  def down
    remove_column :allocations, :responsibility
  end
end
