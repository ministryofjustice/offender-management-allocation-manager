class AddTierChangeTable < ActiveRecord::Migration[5.2]
  def up
    create_table :tier_changes do |t|
      t.string :noms_no
      t.string :old_tier
      t.string :new_tier
      t.timestamps
    end
    add_index :tier_changes, [:noms_no]
  end

  def down
    drop_table :tier_changes
  end
end
