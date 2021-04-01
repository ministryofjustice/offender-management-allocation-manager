# frozen_string_literal: true

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
    # This now needs to cope with nils anywhere in the list - items are 'swept up'
    # until an actual prison change - as some items may not have an associated prison
    current_prison = nil
    allocations_for_prison = []
    @array.each do |history_entry|
      if history_entry.prison == current_prison || current_prison.nil? || history_entry.prison.nil?
        allocations_for_prison << history_entry
        current_prison = history_entry.prison if current_prison.nil?
      else
        yield(current_prison, allocations_for_prison)
        allocations_for_prison = [history_entry]
        current_prison = history_entry.prison
      end
    end
    yield(current_prison, allocations_for_prison) unless allocations_for_prison.empty?
  end
end
