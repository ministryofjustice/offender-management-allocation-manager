class AddIndexToStaff < ActiveRecord::Migration[5.2]
  def up
    add_index :staff, :staff_id
  end

  def down
    remove_index :staff, :staff_id
  end
end
