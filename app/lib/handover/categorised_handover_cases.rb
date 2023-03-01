module Handover
  class CategorisedHandoverCases
    def initialize(offenders)
      @all_offenders_by_no = offenders.index_by(&:offender_no)
      all_offender_ids = @all_offenders_by_no.keys
      all_upcoming = build_cases CalculatedHandoverDate.by_upcoming_handover(offender_ids: all_offender_ids).to_a
      @upcoming_without_com, upcoming_with_com = all_upcoming.partition { |hc| hc.offender.allocated_com_name.nil? }

      past_handover = build_cases CalculatedHandoverDate.by_handover_in_progress(offender_ids: all_offender_ids).to_a

      @in_progress = past_handover + upcoming_with_com
      @overdue_tasks = past_handover.reject { |hc| hc.offender.handover_progress_complete? }
      @com_allocation_overdue = build_cases(
        CalculatedHandoverDate.by_com_allocation_overdue(offender_ids: all_offender_ids).to_a)
    end

    def upcoming
      @upcoming_without_com
    end

    attr_reader :in_progress, :overdue_tasks, :com_allocation_overdue

  private

    def build_cases(cal_handover_dates)
      cal_handover_dates.map do |chd|
        HandoverCase.new(@all_offenders_by_no[chd.nomis_offender_id], chd)
      end
    end
  end
end
