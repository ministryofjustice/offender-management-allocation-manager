class HandoverCasesList
  def initialize(staff_member:)
    offenders = staff_member.allocations # @type [AllocatedOffender]
    @all_offenders_by_no = offenders.index_by(&:offender_no)
    all_upcoming = build_tuple CalculatedHandoverDate.by_upcoming_handover(offender_ids: @all_offenders_by_no.keys).to_a
    @upcoming_without_com, = all_upcoming.partition { |_, offender| offender.allocated_com_name.nil? }
  end

  def upcoming
    @upcoming_without_com
  end

private

  def build_tuple(cal_handover_dates)
    cal_handover_dates.map { |chd| [chd, @all_offenders_by_no[chd.nomis_offender_id]] }
  end
end
