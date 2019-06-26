class AddCrnToTierChange < ActiveRecord::Migration[5.2]
  def up
    add_column :tier_changes, :crn, :string
  end

  def down
    remove_column :tier_changes, :crn
  end
end
