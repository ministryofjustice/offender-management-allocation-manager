class AddEarlyAllocationFields < ActiveRecord::Migration[6.0]
  def change
    change_table :early_allocations do |t|
      # These first 3 fields should be made non-nullable in the future
      t.string :prison
      t.string :created_by_firstname
      t.string :created_by_lastname
      t.string :updated_by_firstname
      t.string :updated_by_lastname
    end
  end
end
