class CreateAllocations < ActiveRecord::Migration[5.2]
  def up
    create_table :allocations do |t|
      t.string :offender_no
      t.string :offender_id
      t.string :prison
      t.string :allocated_at_tier
      t.string :reason
      t.string :note
      t.string :created_by
      t.boolean :active
      t.references :staff, foreign_key: { to_table: :staff }
      t.timestamps
    end
  end

  def down
    drop_table :allocations
  end
end
