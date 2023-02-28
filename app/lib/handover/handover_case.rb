class Handover::HandoverCase
  # we pass calculated handover date explicitly instead of finding it ourselves because: (1) its not our job to find it,
  # and (2) the CategorisedHandoverCases factories will have found them already when it initialises this class
  def initialize(calculated_handover_date, allocated_offender)
    raise ArgumentError unless calculated_handover_date.is_a?(CalculatedHandoverDate)
    raise ArgumentError unless allocated_offender.is_a?(AllocatedOffender)

    @offender = allocated_offender
    @calculated_handover_date = calculated_handover_date
  end

  attr_reader :offender, :calculated_handover_date

  def ==(other)
    [@offender, @calculated_handover_date] == [other.offender, other.calculated_handover_date]
  end

  delegate :last_name, to: :offender, prefix: true
  delegate :staff_member, :allocated_com_name, :tier, :handover_progress_complete?, to: :offender
  delegate :last_name, to: :staff_member, prefix: true
  delegate :handover_date, to: :calculated_handover_date

  def com_allocation_days_overdue(relative_to_date: Time.zone.now.to_date)
    raise ArgumentError, 'Handover date not set' unless handover_date

    (relative_to_date - handover_date).to_i
  end
end
