# frozen_string_literal: true

class AllocationList < Array
  def grouped_by_prison(&_block)
    # Groups the allocations in this array by the prison that it relates to.
    # Unfortunately we can't put this in a hash because a prisoner may have been
    # to a prison more than once, so a visit to Cardiff, then Leeds, then Cardiff
    # would mean they are out of order.
    #
    # Each time a new prison is found in the list, we yield the current prison
    # and all of the allocations we have captured so far to the caller via the passed
    # block.
    return [] if empty?

    idx = 0
    last_idx = count

    loop do
      prison = self[idx].prison

      slice_of_this = slice(idx, last_idx - idx)
      allocations_for_prison = slice_of_this.take_while { |p|
        p.prison == prison
      }

      yield(prison, allocations_for_prison)

      idx += allocations_for_prison.count
      break if idx >= last_idx
    end
  end
end
