module Handover
  class CategorisedHandoverCasesForHomd
    def initialize(prison)
      @categorised_handover_cases = CategorisedHandoverCases.new(prison.primary_allocated_offenders)
    end

    delegate :upcoming, :in_progress, :overdue_tasks, :com_allocation_overdue, to: :categorised_handover_cases

  private

    attr_reader :categorised_handover_cases
  end
end
