# frozen_string_literal: true

class MpcOffender
  delegate :get_image,
           :recalled?, :immigration_case?, :indeterminate_sentence?,
           :sentenced?, :over_18?, :describe_sentence, :legal_status, :civil_sentence?,
           :sentence_start_date, :conditional_release_date, :automatic_release_date, :parole_eligibility_date,
           :tariff_date, :post_recall_release_date, :licence_expiry_date,
           :home_detention_curfew_actual_date, :home_detention_curfew_eligibility_date,
           :prison_arrival_date, :earliest_release_date, :earliest_release, :latest_temp_movement_date, :release_date,
           :date_of_birth, :main_offence, :awaiting_allocation_for, :location,
           :category_label, :complexity_level, :category_code, :category_active_since,
           :first_name, :last_name, :full_name_ordered, :full_name,
           :inside_omic_policy?, :offender_no, :prison_id, :restricted_patient?, :age, :booking_id, to: :@api_offender

  delegate :crn, :manual_entry?, :tier, :mappa_level, to: :case_information
  # These fields make sense to be nil when the case information is nil - the others dont
  delegate :ldu_email_address, :team_name, :ldu_name, :active_vlo?, :welsh_offender, to: :case_information, allow_nil: true

  delegate :victim_liaison_officers,
           :handover_progress_task_completion_data, :handover_progress_complete?, :handover_type, :enhanced_handover?,
           :current_parole_review, :previous_parole_reviews, :most_recent_parole_review, :parole_reviews,
           :case_information, to: :offender

  attr_reader :prison, :offender

  alias_method :nomis_offender_id, :offender_no
  alias_method :probation_record, :case_information
  alias_method :model, :offender

  def initialize(prison:, offender:, prison_record:)
    @prison = prison
    @offender = offender
    @api_offender = prison_record # @type HmppsApi::Offender
  end

  # TODO: - view method in model needs to be removed
  def case_owner
    if pom_responsible?
      'Custody'
    else
      'Community'
    end
  end

  def com_allocation_days_overdue(relative_to_date: Time.zone.now.to_date)
    raise ArgumentError, 'Handover date not set' unless handover_date

    (relative_to_date - handover_date).to_i
  end

  def needs_a_com?
    case_information.present? && (com_responsible? || com_supporting?) && allocated_com_name.blank?
  end

  def pom_responsible?
    responsibility.try(:pom_responsible?)
  end

  def pom_supporting?
    responsibility.try(:pom_supporting?)
  end

  def com_responsible?
    responsibility.try(:com_responsible?)
  end

  def com_supporting?
    responsibility.try(:com_supporting?)
  end

  def allocated_com_name
    case_information.com_name
  end

  def allocated_com_email
    case_information.com_email
  end

  def responsibility_override?
    @offender.responsibility.present?
  end

  # Early allocation methods
  def early_allocation?
    latest_early_allocation.present? && !licence_expiry_date&.before?(Time.zone.today)
  end

  def latest_early_allocation
    allocation = early_allocations&.last
    allocation if allocation.present? && allocation.created_within_referral_window? && (allocation.eligible? || allocation.community_decision?)
  end

  def early_allocations
    @offender.early_allocations.where('created_at::date >= ?', sentence_start_date)
  end

  def needs_early_allocation_notify?
    # The case_information.present? check is needed as one of the dates is THD which is currently inside case_information
    case_information.present? &&
      within_early_allocation_window? &&
      early_allocations.active_pre_referral_window.any? &&
      early_allocations.post_referral_window.empty?
  end

  def within_early_allocation_window?
    earliest_date = [
      tariff_date,
      parole_eligibility_date,
      target_hearing_date,
      automatic_release_date,
      conditional_release_date
    ].compact.min
    earliest_date.present? && earliest_date <= Time.zone.today + 18.months
  end

  # handover methods

  def handover_start_date
    model.calculated_handover_date&.start_date
  end

  def handover_date
    model.calculated_handover_date&.handover_date
  end

  def handover_last_calculated_at
    model.calculated_handover_date&.last_calculated_at
  end

  def handover_reason
    handover.reason_text
  end

  def should_send_handover_follow_up_email?
    sentenced? && prison.active? && handover_start_date == Time.zone.today - 1.week
  end

  # LEGACY - does processing when called to blank out handover date if responsibility is COM. Use #handover_date
  # which returns the actual handover date on the CalculatedHandoverDate model
  def responsibility_handover_date
    handover.handover_date
  end

  # parole methods

  def target_hearing_date
    @target_hearing_date ||= parole_reviews
      .ordered_by_sortable_date
      .for_sentences_starting(sentence_start_date)
      .pluck(:target_hearing_date)
      .last
  end

  def approaching_parole?
    next_parole_date.present?
  end

  def next_parole_date
    [target_hearing_date, tariff_date, parole_eligibility_date].compact.sort.find do |date|
      date.between?(Time.zone.now, 10.months.from_now.end_of_day)
    end
  end

  # Separate from next_parole_date as parole case index view sorts by next_parole_date, so it seemed sensible to avoid changing default rails behaviour
  # for the sake of saving a couple of simple, albeit slightly inefficient, comparisons.
  def next_parole_date_type
    return nil if next_parole_date.nil?

    case next_parole_date
    when tariff_date
      'TED'
    when parole_eligibility_date
      'PED'
    when target_hearing_date
      'Target hearing date'
    end
  end

  def most_recent_completed_parole_review_for_sentence
    @most_recent_completed_parole_review_for_sentence ||= parole_reviews
      .ordered_by_sortable_date
      .completed
      .for_sentences_starting(sentence_start_date)
      .last
  end

  def no_parole_outcome?
    most_recent_completed_parole_review_for_sentence&.no_hearing_outcome?
  end

  def parole_outcome_not_release?
    most_recent_completed_parole_review_for_sentence&.outcome_is_not_release?
  end

  def thd_12_or_more_months_from_now?
    target_hearing_date && target_hearing_date >= 12.months.from_now
  end

  def display_current_parole_info?
    tariff_date.present? || parole_eligibility_date.present? || current_parole_review.present?
  end

  def sentences
    @sentences ||= Offenders::Sentences.new(booking_id:)
  end

  def pom_tasks
    @pom_tasks ||= build_pom_tasks
  end

  # early allocation methods

  def early_allocation_state
    if early_allocation?
      :eligible
    elsif early_allocation_active?
      :decision_pending
    elsif within_early_allocation_window? &&
      early_allocations.reject(&:created_within_referral_window?).select { |ea| %w[eligible discretionary].include?(ea.outcome) }.any?
      :call_to_action # need to complete a new assessment
    elsif early_allocation_notes?
      :assessment_saved
    end
  end

  def prison_timeline
    @prison_timeline ||= HmppsApi::PrisonTimelineApi.get_prison_timeline(offender_no)

  # Temp fix while Prison API prison timeline sometimes returns 500 and 404
  # for some offenders
  rescue Faraday::ServerError, Faraday::ResourceNotFound
    nil
  end

  def additional_information
    return [] if prison_timeline.nil?

    attended_prisons = prison_timeline['prisonPeriod'].map { |p| p['prisons'] }.flatten

    # Remove only ONE of any prison codes that match the current prison
    previously_attended_prisons = (attended_prisons.reject { |p| p == prison.code }) +
      attended_prisons.select { |p| p == prison.code }.drop(1)

    [].tap do |output|
      output << 'Recall' if recalled? && previously_attended_prisons.any?

      output << if previously_attended_prisons.empty?
                  'New to custody'
                elsif previously_attended_prisons.include?(prison.code)
                  'Returning to this prison'
                else
                  'New to this prison'
                end
    end
  end

  def mappa_details
    OffenderService.get_mappa_details(crn)
  end

  def rosh_summary
    return { status: :unable } if case_information.blank?
    return { status: :unable } if crn.blank?

    begin
      risks = HmppsApi::AssessRisksAndNeedsApi.get_rosh_summary(crn)
      risks_summary = risks['summary']
    rescue Faraday::ResourceNotFound
      return { status: :missing }
    rescue Faraday::ForbiddenError
      return { status: :unable }
    rescue Faraday::ServerError
      return { status: :unable }
    end

    if risks_summary['overallRiskLevel'].blank?
      Rails.logger.warn('event=risks_api_blank_value|overallRiskLevel is blank')
      return { status: :unable }
    end

    custody = {}.tap do |out|
      if risks_summary['riskInCustody'].present?
        risks_summary['riskInCustody'].each do |level, groups|
          groups.each { |group| out[group] = level.tr('_', ' ').downcase }
        end
      end
    end

    community = {}.tap do |out|
      if risks_summary['riskInCommunity'].present?
        risks_summary['riskInCommunity'].each do |level, groups|
          groups.each { |group| out[group] = level.tr('_', ' ').downcase }
        end
      end
    end

    {
      status: 'found',
      overall: risks_summary['overallRiskLevel'].upcase,
      last_updated: Date.parse(risks['assessedOn']),
      custody: {
        children: custody['Children'],
        public: custody['Public'],
        known_adult: custody['Known Adult'] || custody['Know adult'],
        staff: custody['Staff'],
        prisoners: custody['Prisoners']
      },
      community: {
        children: community['Children'],
        public: community['Public'],
        known_adult: community['Known Adult'],
        staff: community['Staff'],
        prisoners: nil
      }
    }
  end

  def active_alert_labels
    active_alerts = HmppsApi::PrisonAlertsApi.alerts_for(offender_no)
      .select { |alert| alert['isActive'] }
      .sort_by { |alert| alert['createdAt'] }
    active_alerts.map { |alert| alert.dig('alertCode', 'description') }
  end

  def recommended_pom_type
    RecommendationService.recommended_pom_type(self)
  end

  def attributes_to_archive
    attr_names = %w[
      recalled?
      immigration_case?
      indeterminate_sentence?
      sentenced?
      over_18?
      describe_sentence
      civil_sentence?
      sentence_start_date
      conditional_release_date
      automatic_release_date
      parole_eligibility_date
      tariff_date
      post_recall_release_date
      licence_expiry_date
      home_detention_curfew_actual_date
      home_detention_curfew_eligibility_date
      prison_arrival_date
      earliest_release_date
      earliest_release
      earliest_release_for_handover
      latest_temp_movement_date
      release_date
      date_of_birth
      main_offence
      awaiting_allocation_for
      location
      category_label
      complexity_level
      category_code
      category_active_since
      first_name
      last_name
      full_name_ordered
      full_name
      inside_omic_policy?
      offender_no
      prison_id
      restricted_patient?
      crn
      manual_entry?
      handover_type
      tier
      mappa_level
      welsh_offender
      ldu_email_address
      team_name
      ldu_name
      allocated_com_name
      allocated_com_email
      target_hearing_date
      early_allocation_state
    ]

    attr_names.index_with { |attr_name| send(attr_name) }
  end

  def released?(relative_to_date: Time.zone.now.utc.to_date)
    return false if earliest_release_date.nil?

    earliest_release_date <= relative_to_date
  end

  def has_com?
    allocated_com_name.present? || allocated_com_email.present?
  end

  def earliest_release_for_handover
    Handover::HandoverCalculation.calculate_earliest_release(
      is_indeterminate: indeterminate_sentence?,
      tariff_date: tariff_date,
      target_hearing_date: target_hearing_date,
      parole_eligibility_date: parole_eligibility_date,
      automatic_release_date: automatic_release_date,
      conditional_release_date: conditional_release_date,
    )
  end

  def determinate_parole?
    parole_eligibility_date.present?
  end

  def active_allocation
    @active_allocation ||= AllocationHistory.active_allocations_for_prison(prison.code).find_by(nomis_offender_id: offender_no)
  end

  def to_allocated_offender
    if active_allocation
      AllocatedOffender.new(active_allocation.primary_pom_nomis_id, active_allocation, self)
    else
      nil
    end
  end

  def policy_case?
    Offenders::PrisonPolicies.new(self).policy_case?
  end

  def open_prison_rules_apply?
    Offenders::PrisonPolicies.new(self).open_prison_rules_apply?
  end

  def in_womens_prison?
    Offenders::PrisonPolicies.new(self).in_womens_prison?
  end

  def in_open_conditions?
    Offenders::PrisonPolicies.new(self).in_open_conditions?
  end

private

  def early_allocation_notes?
    if early_allocations.present?
      !early_allocations.last.created_within_referral_window? || !early_allocations.last.community_decision_eligible_or_automatically_eligible?
    end
  end

  def early_allocation_active?
    early_allocations.present? && early_allocations.last.awaiting_community_decision?
  end

  def handover
    @handover ||= if pom_responsible?
                    HandoverDateService.handover(self)
                  else
                    OffenderHandover::COM_NO_HANDOVER_DATE
                  end
  end

  def responsibility
    @responsibility ||= @offender.responsibility || \
      @offender.calculated_handover_date || \
      HandoverDateService.handover(self)
  end

  def build_pom_tasks
    tasks = []

    # We don't want the task to be created if there's no parole review, if the
    # most recent parole review is yet to have a hearing outcome, or if there is
    # already a date that the hearing outcome was received.
    if most_recent_parole_review.present? &&
      !most_recent_parole_review.no_hearing_outcome? &&
      most_recent_parole_review.hearing_outcome_received_on.blank?
      tasks << PomTask.new(self, :parole_outcome_date, most_recent_parole_review.review_id)
    end

    if early_allocations.present?
      tasks << PomTask.new(self, :early_allocation_decision)
    end

    tasks
  end
end
