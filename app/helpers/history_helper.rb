# frozen_string_literal: true

module HistoryHelper
  def allocation_list(alloc_vlo_history, early_allocations, email_history)
    history = alloc_vlo_history + email_history
    early_allocations.each do |ea|
      history.append(EarlyAllocationHistory.new(ea))
      if ea.updated_by_firstname.present?
        history.append(EarlyAllocationDecision.new(ea))
      end
    end
    AllocationList.new(history.sort_by(&:created_at)).to_a.reverse.map { |prison, allocations| [prison, allocations.reverse] }
  end
end
