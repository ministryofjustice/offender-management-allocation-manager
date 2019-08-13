class AddPrisonIndexToAllocationVersion < ActiveRecord::Migration[5.2]
  def change
    change_table :allocation_versions do |t|
      t.index :prison
    end
  end
end
