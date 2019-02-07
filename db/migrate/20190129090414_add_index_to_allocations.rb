class AddIndexToAllocations < ActiveRecord::Migration[5.2]
  def up
    add_index :allocations, :offender_no
    add_index :allocations, :offender_id
  end

  def down
    remove_index :allocations, :offender_no
    remove_index :allocations, :offender_id
  end
end
