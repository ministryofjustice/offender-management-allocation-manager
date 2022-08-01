class HandoverCasesList
  def initialize(staff_member:)
    allocated_offenders = staff_member.allocations
    @allocated_offenders_by_id = allocated_offenders.index_by(&:offender_no)
    @upcoming = CalculatedHandoverDate.by_upcoming_handover(offender_ids: allocated_offenders.map(&:offender_no)).to_a
  end

  def upcoming
    @upcoming.map { |chd| [chd, @allocated_offenders_by_id[chd.nomis_offender_id]] }
  end
end
