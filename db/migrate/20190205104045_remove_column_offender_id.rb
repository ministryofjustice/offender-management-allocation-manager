class RemoveColumnOffenderId < ActiveRecord::Migration[5.2]
  def up
    remove_column :allocations, :offender_id
  end

  def down
    add_column :allocations, :offender_id, :string
  end
end
