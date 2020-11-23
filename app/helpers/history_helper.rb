# frozen_string_literal: true

module HistoryHelper
  def allocation_list(history)
    AllocationList.new(history).to_a.reverse.map { |prison, allocations| [prison, allocations.reverse] }
  end
  #rubocop:disable Rails/HelperInstanceVariable
  class AllocationList
    include Enumerable

    def initialize(array)
      @array = array
    end

    def each
      # Groups the allocations in this array by the prison that it relates to.
      # Unfortunately we can't put this in a hash because a prisoner may have been
      # to a prison more than once, so a visit to Cardiff, then Leeds, then Cardiff
      # would mean they are out of order.
      #
      # Each time a new prison is found in the list, we yield the current prison
      # and all of the allocations we have captured so far to the caller via the passed
      # block.
      #
      # This now needs to cope with nils at the start and middle of list - items are 'swept up'
      # until an actual prison change - as some items may not have an associated prison
      current_prison = nil
      allocations_for_prison = []
      @array.each do |item|
        if item.prison == current_prison || current_prison.nil?
          allocations_for_prison << item
        else
          yield(current_prison, allocations_for_prison)
          allocations_for_prison = [item]
        end
        current_prison = item.prison
      end
      yield(current_prison, allocations_for_prison) unless allocations_for_prison.empty?
    end
  end
  #rubocop:enable Rails/HelperInstanceVariable
end
