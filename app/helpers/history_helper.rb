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
      return if @array.empty?

      idx = 0
      last_idx = @array.count

      loop do
        prison = @array[idx].prison

        slice_of_this = @array.slice(idx, last_idx - idx)
        allocations_for_prison = slice_of_this.take_while { |p|
          # The nil? piece here is impossible to test as we have changed our minds about
          # nilling out prison in allocation, however in production we still have some
          # history records in the 'versions' table with a nil prison in them.
          # These need to be swept up as belonging to the 'current' prison as they are typically de-allocations
          p.prison == prison || p.prison.nil?
        }

        yield(prison, allocations_for_prison)

        idx += allocations_for_prison.count
        break if idx >= last_idx
      end
    end
  end
  #rubocop:enable Rails/HelperInstanceVariable
end
