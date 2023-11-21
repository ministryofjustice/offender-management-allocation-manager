class AddLastCalculatedToCalculatedHandoverDate < ActiveRecord::Migration[6.1]
  def up
    add_column :calculated_handover_dates, :last_calculated_at, :datetime
  end

  def down
    remove_column :calculated_handover_dates, :last_calculated_at
  end
end
