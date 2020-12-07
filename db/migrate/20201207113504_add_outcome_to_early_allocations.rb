class AddOutcomeToEarlyAllocations < ActiveRecord::Migration[6.0]
  def change
    change_table :early_allocations do |t|
      t.string :outcome
    end
  end
end
