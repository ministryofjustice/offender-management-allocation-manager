class AddCommunityDecisionToEarlyAllocation < ActiveRecord::Migration[5.2]
  def change
    change_table :early_allocations do |t|
      t.boolean :community_decision
    end
  end
end
