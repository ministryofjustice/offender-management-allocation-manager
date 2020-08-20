module HistoryHelper
  def allocation_list(history)
    AllocationList.new(history).to_a.reverse.map { |prison, allocations| [prison, allocations.reverse] }
  end
end
