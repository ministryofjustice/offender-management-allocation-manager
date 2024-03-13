class OffenderSampleService
  FILTERS = {
    badge_sentence_determinate:
      ->(offender) { !offender.indeterminate_sentence? },
    badge_sentence_indeterminate:
      ->(offender) { offender.indeterminate_sentence? },
    badge_parole:
      lambda { |offender|
        offender.tariff_date.present? || offender.parole_eligibility_date.present? || \
                      (offender.indeterminate_sentence? && offender.target_hearing_date.present?)
      },
    badge_recall:
      ->(offender) { offender.recalled? },
    badge_early_allocation_eligible:
      ->(offender) { offender.early_allocation_state == :eligible },
    badge_early_allocation_decision_pending:
      ->(offender) { offender.early_allocation_state == :decision_pending },
    badge_early_allocation_assessment_saved:
      ->(offender) { offender.early_allocation_state.in?(%i[assessment_saved call_to_action]) },
    badge_restricted_patient:
      ->(offender) { offender.restricted_patient? },
    badge_complexity_level_high:
      ->(offender) { offender.complexity_level == 'high' },
    badge_complexity_level_medium:
      ->(offender) { offender.complexity_level == 'medium' },
    badge_complexity_level_low:
      ->(offender) { offender.complexity_level == 'low' },
    badge_vlo_contact:
      ->(offender) { offender.active_vlo? || offender.victim_liaison_officers.any? },
    has_rosh_summary:
      ->(offender) { offender.rosh_summary[:status] == 'found' }
  }.freeze

  def initialize(prison_code: nil, offenders: nil, criteria: [])
    @prison_code = prison_code
    @offenders   = offenders
    @criteria    = criteria
    @filters     = FILTERS.values_at(*criteria).compact

    unless prison_code || offenders
      raise ArgumentError, 'Please provide either :prison_code or :offenders in order to get a sample of offenders'
    end
  end

  def results
    sampled_offenders = offenders.filter do |offender|
      meets_any_criteria?(offender) \
        && either_has_future_release_date_or_indeterminate_release?(offender) \
        && offender.case_information.present?
    end

    sampled_offenders.sort_by(&:full_name)
  end

private

  def meets_any_criteria?(offender)
    @filters.any? { |filter| filter.call(offender) }
  end

  def either_has_future_release_date_or_indeterminate_release?(offender)
    offender.release_date&.future? || (@criteria.include?(:badge_sentence_indeterminate) && offender.indeterminate_sentence?)
  end

  def offenders
    @offenders ||= OffenderService.get_offenders_in_prison(Prison.find_by(code: @prison_code))
  end
end
