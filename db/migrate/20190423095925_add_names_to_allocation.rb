class AddNamesToAllocation < ActiveRecord::Migration[5.2]
  def up
    add_column :allocations, :pom_name, :text
    add_column :allocations, :created_by_name, :text
  end

  def down
    remove_column :allocations, :pom_name
    remove_column :allocations, :created_by_name
  end
end
