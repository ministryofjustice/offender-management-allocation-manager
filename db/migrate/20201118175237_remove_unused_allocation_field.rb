class RemoveUnusedAllocationField < ActiveRecord::Migration[6.0]
  def change
    remove_column :allocations, :created_by_username, :string
  end
end
