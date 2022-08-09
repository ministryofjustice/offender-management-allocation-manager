class HandoverCasesList
  def initialize(staff_member:)
    offenders = staff_member.unreleased_allocations # @type [AllocatedOffender]
    @all_offenders_by_no = offenders.index_by(&:offender_no)
    all_offender_ids = @all_offenders_by_no.keys
    all_upcoming = build_tuple CalculatedHandoverDate.by_upcoming_handover(offender_ids: all_offender_ids).to_a
    @upcoming_without_com, upcoming_with_com = all_upcoming.partition { |_, offender| offender.allocated_com_name.nil? }
    @in_progress = build_tuple CalculatedHandoverDate.by_handover_in_progress(offender_ids: all_offender_ids).to_a
    @in_progress += upcoming_with_com
  end

  def upcoming
    @upcoming_without_com
  end

  attr_reader :in_progress

private

  def build_tuple(cal_handover_dates)
    cal_handover_dates.map { |chd| [chd, @all_offenders_by_no[chd.nomis_offender_id]] }
  end
end
