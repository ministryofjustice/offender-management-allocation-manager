module Handover
  class CategorisedHandoverCases
    def initialize(offenders)
      @offenders_by_id = offenders.index_by(&:offender_no)
      @offender_ids = @offenders_by_id.keys

      upcoming_with_com, @upcoming = cases(CalculatedHandoverDate.by_upcoming_handover(offender_ids:)).partition(&:allocated_com_name)
      past_handover = cases(CalculatedHandoverDate.by_handover_in_progress(offender_ids:))
      @in_progress = past_handover + upcoming_with_com
      @overdue_tasks = past_handover.reject(&:handover_progress_complete?)
      @com_allocation_overdue = cases(CalculatedHandoverDate.by_com_allocation_overdue(offender_ids:))
    end

    attr_reader :upcoming, :in_progress, :overdue_tasks, :com_allocation_overdue

  private

    attr_reader :offender_ids

    def cases(calculated_handover_dates)
      calculated_handover_dates.map do |calculated_handover_date|
        @offenders_by_id[calculated_handover_date.nomis_offender_id]
      end
    end
  end
end
