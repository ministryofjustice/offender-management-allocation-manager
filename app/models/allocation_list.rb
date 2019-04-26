# frozen_string_literal: true

class AllocationList < Array
  # rubocop:disable Metrics/MethodLength
  def grouped_by_prison!
    # Groups the allocations in this array by the prison that it relates to,
    # ensuring that it takes into account movements between prisons.
    #
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
    # This method consumes the list during processing and so you should not
    # attempt to use it afterwards, it'll be empty, primarily so we're not
    # keeping two entire copies of the list around when there are large numbers
    # of allocations.
    return [] if empty?

    results = []

    loop do
      prison = first.prison
      allocations_for_prison = take_while { |p|
        p.prison == prison
      }

      results << [prison, allocations_for_prison]
      shift(allocations_for_prison.count)

      break if count == 0
    end

    results
  end
  # rubocop:enable Metrics/MethodLength
end
