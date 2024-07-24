class RemoveHandoverDatesFromRecallCases < ActiveRecord::Migration[7.1]
  def up
    CalculatedHandoverDate
      .where(reason: :recall_case)
      .where.not(handover_date: nil, start_date: nil)
      .update(handover_date: nil, start_date: nil)
  end

  def down; end
end
