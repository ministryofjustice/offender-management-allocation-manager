class DropOverridesTable < ActiveRecord::Migration[6.0]
  def change
    drop_table :overrides
  end
end
