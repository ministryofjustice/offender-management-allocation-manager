# frozen_string_literal: true

class AllocationList < Array
  # rubocop:disable Metrics/MethodLength
  def grouped_by_prison
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
    return [] if empty?

    idx = 0
    last_idx = count
    results = []

    loop do
      prison = self[idx].prison

      slice_of_this = slice(idx, last_idx - idx)
      allocations_for_prison = slice_of_this.take_while { |p|
        p.prison == prison
      }
      results << [prison, allocations_for_prison]

      idx += allocations_for_prison.count
      break if idx >= last_idx
    end

    results
  end
  # rubocop:enable Metrics/MethodLength
end
