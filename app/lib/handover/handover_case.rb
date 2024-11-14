class Handover::HandoverCase
  # we pass calculated handover date explicitly instead of finding it ourselves because: (1) its not our job to find it,
  # and (2) the CategorisedHandoverCases factories will have found them already when it initialises this class
  def initialize(allocated_offender, calculated_handover_date)
    raise ArgumentError unless calculated_handover_date.is_a?(CalculatedHandoverDate)
    raise ArgumentError unless allocated_offender.is_a?(AllocatedOffender)

    @offender = allocated_offender
    @calculated_handover_date = calculated_handover_date
  end

  attr_reader :offender, :calculated_handover_date

  def ==(other)
    [@offender, @calculated_handover_date] == [other.offender, other.calculated_handover_date]
  end

  delegate :staff_member, :staff_member_full_name_ordered, :allocated_com_name, :tier, :handover_progress_complete?,
           :earliest_release_for_handover, :com_allocation_days_overdue, :handover_date, :offender_last_name, to: :offender

  def earliest_release_date
    earliest_release_for_handover&.date
  end
end
