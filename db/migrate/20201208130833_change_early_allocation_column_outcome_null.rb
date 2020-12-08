class ChangeEarlyAllocationColumnOutcomeNull < ActiveRecord::Migration[6.0]
  def change
    change_column_null :early_allocations, :outcome, false
  end
end
