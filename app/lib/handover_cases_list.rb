class HandoverCasesList
  def initialize(staff_member:)
    offenders = staff_member.unreleased_allocations # @type [AllocatedOffender]
    @all_offenders_by_no = offenders.index_by(&:offender_no)
    all_offender_ids = @all_offenders_by_no.keys
    all_upcoming = build_tuple CalculatedHandoverDate.by_upcoming_handover(offender_ids: all_offender_ids).to_a
    @upcoming_without_com, upcoming_with_com = all_upcoming.partition { |_, offender| offender.allocated_com_name.nil? }

    past_handover = build_tuple CalculatedHandoverDate.by_handover_in_progress(offender_ids: all_offender_ids).to_a

    @in_progress = past_handover + upcoming_with_com
    @overdue_tasks = past_handover.reject { |_, offender| offender.handover_progress_complete? }
    @com_allocation_overdue = build_tuple(
      CalculatedHandoverDate.by_com_allocation_overdue(offender_ids: all_offender_ids).to_a)
  end

  def upcoming
    @upcoming_without_com
  end

  attr_reader :in_progress, :overdue_tasks, :com_allocation_overdue

private

  def build_tuple(cal_handover_dates)
    cal_handover_dates.map { |chd| [chd, @all_offenders_by_no[chd.nomis_offender_id]] }
  end
end
