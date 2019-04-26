# frozen_string_literal: true

class AllocationList < Array
  # rubocop:disable Metrics/MethodLength
  def grouped_by_prison(&_block)
    # Groups the allocations in this array by the prison that it relates to.
    # Unfortunately we can't put this in a hash because a prisoner may have been
    # to a prison more than once, so a visit to Cardiff, then Leeds, then Cardiff
    # would mean they are out of order.  Instead we need to put it into a structure
    # that looks like
    #
    #    [
    #      ['PrisonA', [alloc1, alloc2]],
    #      ['PrisonB', [alloc3]],
    #      ['PrisonA', [alloc4]],
    #    ]
    #
    # Instead of returning a list, and keeping multiple copies of data in RAM, the
    # caller must provide a block `{ |prison, allocations| ... }` which will be called
    # each time a new prison (row) is built
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
  # rubocop:enable Metrics/MethodLength
end
