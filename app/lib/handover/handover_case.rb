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

  delegate :last_name, to: :offender, prefix: true
  delegate :staff_member, :allocated_com_name, :tier, :handover_progress_complete?, to: :offender
  delegate :last_name, to: :staff_member, prefix: true
  delegate :handover_date, to: :calculated_handover_date

  def com_allocation_days_overdue(relative_to_date: Time.zone.now.to_date)
    raise ArgumentError, 'Handover date not set' unless handover_date

    (relative_to_date - handover_date).to_i
  end

  # We can not calculate the handover date for NPS Indeterminate
  # with parole cases where the TED is in the past as we need
  # the parole board decision which currently is not available to us.
  def earliest_release_for_handover
    if offender.indeterminate_sentence?
      if offender.tariff_date&.future?
        NamedDate[offender.tariff_date, 'TED']
      else
        [
          NamedDate[offender.parole_review_date, 'PRD'],
          NamedDate[offender.parole_eligibility_date, 'PED'],
        ].compact.reject { |nd| nd.date.past? }.min
      end
    elsif offender.case_information&.nps_case?
      possible_dates = [NamedDate[offender.conditional_release_date, 'CRD'], NamedDate[offender.automatic_release_date, 'ARD']]
      NamedDate[offender.parole_eligibility_date, 'PED'] || possible_dates.compact.min
    else
      # CRC can look at HDC date, NPS is not supposed to
      NamedDate[offender.home_detention_curfew_actual_date, 'HDCEA'] ||
        [NamedDate[offender.automatic_release_date, 'ARD'],
         NamedDate[offender.conditional_release_date, 'CRD'],
         NamedDate[offender.home_detention_curfew_eligibility_date, 'HDCED']].compact.min
    end
  end

  def earliest_release_date
    earliest_release_for_handover&.date
  end
end
