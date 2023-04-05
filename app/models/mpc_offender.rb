# frozen_string_literal: true

class MpcOffender
  delegate :get_image,
           :recalled?, :immigration_case?, :indeterminate_sentence?,
           :sentenced?, :over_18?, :describe_sentence, :civil_sentence?,
           :sentence_start_date, :conditional_release_date, :automatic_release_date, :parole_eligibility_date,
           :tariff_date, :post_recall_release_date, :licence_expiry_date,
           :home_detention_curfew_actual_date, :home_detention_curfew_eligibility_date,
           :prison_arrival_date, :earliest_release_date, :earliest_release, :latest_temp_movement_date, :release_date,
           :date_of_birth, :main_offence, :awaiting_allocation_for, :location,
           :category_label, :complexity_level, :category_code, :category_active_since,
           :first_name, :last_name, :full_name_ordered, :full_name,
           :inside_omic_policy?, :offender_no, :prison_id, :restricted_patient?, :age, to: :@api_offender

  delegate :crn, :case_allocation, :manual_entry?, :nps_case?,
           :tier,
           :mappa_level, :welsh_offender, to: :probation_record

  delegate :active_vlo?, to: :probation_record, allow_nil: true

  delegate :victim_liaison_officers, :handover_progress_task_completion_data, :handover_progress_complete?,
           to: :@offender

  # These fields make sense to be nil when the probation record is nil - the others dont
  delegate :ldu_email_address, :team_name, :ldu_name, to: :probation_record, allow_nil: true

  delegate :start_date, to: :handover, prefix: true

  attr_reader :case_information, :prison

  def initialize(prison:, offender:, prison_record:)
    @prison = prison
    @offender = offender
    @api_offender = prison_record # @type HmppsApi::Offender
    @case_information = offender.case_information
  end

  def probation_record
    @case_information
  end

  # TODO: - view method in model needs to be removed
  def case_owner
    if pom_responsible?
      'Custody'
    else
      'Community'
    end
  end

  def needs_a_com?
    @case_information.present? && (com_responsible? || com_supporting?) && allocated_com_name.blank?
  end

  def pom_responsible?
    if @offender.responsibility.nil?
      HandoverDateService.handover(self).custody_responsible?
    else
      @offender.responsibility.value == Responsibility::PRISON
    end
  end

  def pom_supporting?
    if @offender.responsibility.nil?
      HandoverDateService.handover(self).custody_supporting?
    else
      @offender.responsibility.value == Responsibility::PROBATION
    end
  end

  def com_responsible?
    if @offender.responsibility.nil?
      HandoverDateService.handover(self).community_responsible?
    else
      @offender.responsibility.value == Responsibility::PROBATION
    end
  end

  def com_supporting?
    if @offender.responsibility.nil?
      HandoverDateService.handover(self).community_supporting?
    else
      # Overrides to prison aren't actually possible in the UI
      # If they were, we'd somehow need to decide whether COM is supporting or not involved
      @offender.responsibility.value == Responsibility::PRISON
    end
  end

  def allocated_com_name
    @case_information.com_name
  end

  def allocated_com_email
    @case_information.com_email
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
    # The probation_record.present? check is needed as one of the dates is PRD which is currently inside case_information
    @case_information.present? &&
      within_early_allocation_window? &&
      early_allocations.active_pre_referral_window.any? &&
      early_allocations.post_referral_window.empty?
  end

  def within_early_allocation_window?
    earliest_date = [
      tariff_date,
      parole_eligibility_date,
      parole_review_date,
      automatic_release_date,
      conditional_release_date
    ].compact.min
    earliest_date.present? && earliest_date <= Time.zone.today + 18.months
  end

  # handover methods

  def handover_reason
    handover.reason_text
  end

  def responsibility_handover_date
    handover.handover_date
  end

  # early allocation methods

  def parole_review_date
    @offender.parole_record.parole_review_date if @offender.parole_record.present?
  end

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

  def trigger_early_allocation_event
    calc_status = if @offender.calculated_early_allocation_status.present?
                    @offender.calculated_early_allocation_status.tap { |ea| ea.assign_attributes(eligible: early_allocation?) }
                  else
                    @offender.build_calculated_early_allocation_status(eligible: early_allocation?)
                  end
    if calc_status.changed?
      calc_status.save!
      EarlyAllocationEventService.send_early_allocation(calc_status)
    end
  end

  def prison_timeline
    @prison_timeline ||= HmppsApi::PrisonTimelineApi.get_prison_timeline(offender_no)

  # Temp fix while Prison API prison timeline sometimes returns 500
  # for some offenders
  rescue Faraday::ServerError
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
    return { status: :unable } if probation_record.blank?
    return { status: :unable } if crn.blank?

    begin
      risks = HmppsApi::AssessRisksAndNeedsApi.get_rosh_summary(crn)
    rescue Faraday::ResourceNotFound
      return { status: :missing }
    rescue Faraday::ServerError
      return { status: :unable }
    end

    custody = {}.tap do |out|
      if risks['riskInCustody'].present?
        risks['riskInCustody'].each do |level, groups|
          groups.each { |group| out[group] = level.tr('_', ' ').downcase }
        end
      end
    end

    community = {}.tap do |out|
      if risks['riskInCommunity'].present?
        risks['riskInCommunity'].each do |level, groups|
          groups.each { |group| out[group] = level.tr('_', ' ').downcase }
        end
      end
    end

    {
      status: 'found',
      overall: risks['overallRiskLevel'].upcase,
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
    all_alerts = HmppsApi::PrisonApi::OffenderApi.get_offender_alerts(offender_no)
    sorted_active_alerts = all_alerts.select { |a| a['active'] && !a['expired'] }.sort_by { |a| a['dateCreated'] }.reverse
    sorted_active_alerts.map { |a| a['alertCodeDescription'] }.uniq
  end

  def model
    @offender
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
      case_allocation
      manual_entry?
      nps_case?
      tier
      mappa_level
      welsh_offender
      ldu_email_address
      team_name
      ldu_name
      allocated_com_name
      allocated_com_email
      parole_review_date
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

  # We can not calculate the handover date for NPS Indeterminate
  # with parole cases where the TED is in the past as we need
  # the parole board decision which currently is not available to us.
  def earliest_release_for_handover
    if indeterminate_sentence?
      if tariff_date&.future?
        NamedDate[tariff_date, 'TED']
      else
        [
          NamedDate[parole_review_date, 'PRD'],
          NamedDate[parole_eligibility_date, 'PED'],
        ].compact.reject { |nd| nd.date.past? }.min
      end
    elsif case_information&.nps_case?
      possible_dates = [NamedDate[conditional_release_date, 'CRD'], NamedDate[automatic_release_date, 'ARD']]
      NamedDate[parole_eligibility_date, 'PED'] || possible_dates.compact.min
    else
      # CRC can look at HDC date, NPS is not supposed to
      NamedDate[home_detention_curfew_actual_date, 'HDCEA'] ||
        [NamedDate[automatic_release_date, 'ARD'],
         NamedDate[conditional_release_date, 'CRD'],
         NamedDate[home_detention_curfew_eligibility_date, 'HDCED']].compact.min
    end
  end

  def determinate_parole?
    parole_eligibility_date.present?
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
                    HandoverDateService::NO_HANDOVER_DATE
                  end
  end
end
