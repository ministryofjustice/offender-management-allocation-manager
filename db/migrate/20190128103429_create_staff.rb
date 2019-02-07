class CreateStaff < ActiveRecord::Migration[5.2]
  def up
    create_table :staff do |t|
      t.string :staff_id
      t.string :working_pattern
      t.string :status
      t.timestamps
    end
  end

  def down
    drop_table :staff
  end
end
