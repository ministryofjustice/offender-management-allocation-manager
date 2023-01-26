module Handover
  class CategorisedHandoverCasesForPom
    def initialize(staff_member)
      @categorised_handover_cases = CategorisedHandoverCases.new(staff_member.unreleased_allocations)
    end

    delegate :upcoming, :in_progress, :overdue_tasks, :com_allocation_overdue, to: :categorised_handover_cases

  private

    attr_reader :categorised_handover_cases
  end
end
