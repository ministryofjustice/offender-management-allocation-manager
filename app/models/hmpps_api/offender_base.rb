module HmppsApi
  class OffenderBase
    delegate :home_detention_curfew_eligibility_date,
             :home_detention_curfew_actual_date,
             :conditional_release_date, :release_date,
             :parole_eligibility_date, :tariff_date,
             :automatic_release_date, :licence_expiry_date,
             :post_recall_release_date, :earliest_release_date,
             to: :sentence

    delegate :indeterminate_sentence?, :immigration_case?,
             to: :@sentence_type

    delegate :tier, :case_allocation, :crn, :mappa_level, :manual_entry?,
             :parole_review_date, :victim_liaison_officers, :updated_at,
             to: :@case_information, allow_nil: true

    attr_accessor :category_code, :date_of_birth, :prison_arrival_date, :sentence, :allocated_pom_name

    attr_reader :first_name, :last_name, :booking_id, :offender_no, :sentence_type, :cell_location, :complexity_level

    def latest_temp_movement_date
      @latest_temp_movement&.movement_date
    end

    # This is needed (sadly) because although when querying by prison these are filtered out,
    # we can query directly (we might have a CaseInformation record) where we don't filter.
    def convicted?
      @convicted_status == 'Convicted'
    end

    def sentenced?
      # A prisoner will have had a sentence calculation and for our purposes
      # this means that they will either have a:
      # 1) Release date, or
      # 2) Parole eligibility date, or
      # 3) HDC release date (homeDetentionCurfewEligibilityDate field).
      # If they do not have any of these we should be checking for a tariff date
      # Once we have all the dates we then need to display whichever is the
      # earliest one.
      return false if sentence&.sentence_start_date.blank?

      sentence.release_date.present? ||
        sentence.parole_eligibility_date.present? ||
        sentence.home_detention_curfew_eligibility_date.present? ||
        sentence.tariff_date.present? ||
        @sentence_type.indeterminate_sentence?
    end

    def early_allocation?
      return false if @case_information.blank?

      early_allocation.present?
    end

    def needs_early_allocation_notify?
      has_case_information? && within_early_allocation_window? && @case_information.early_allocations.suitable_offenders_pre_referral_window.any?
    end

    # Has a CaseInformation record been loaded for this offender?
    def has_case_information?
      @case_information.present?
    end

    def nps_case?
      @case_information&.nps?
    end

    def welsh_offender
      return nil if @case_information.blank?

      @case_information.probation_service == 'Wales'
    end

    def ldu_name
      ldu&.name
    end

    def ldu_email_address
      ldu&.email_address
    end

    def team_name
      @case_information&.team&.name
    end

    def delius_matched?
      @case_information&.manual_entry == false
    end

    def allocated_com_name
      @case_information&.com_name
    end

    def recalled?
      @recall_flag
    end

    def civil_sentence?
      @sentence_type.civil?
    end

    def describe_sentence
      "#{@sentence_type.code} - #{@sentence_type.description}"
    end

    def over_18?
      age >= 18
    end

    def pom_responsibility
      if @responsibility_override.nil?
        HandoverDateService.handover(self).custody
      elsif @responsibility_override.value == Responsibility::PRISON
        # Overrides to prison aren't actually possible in the UI
        HandoverDateService::RESPONSIBLE
      else
        HandoverDateService::SUPPORTING
      end
    end

    def com_responsibility
      if @responsibility_override.nil?
        HandoverDateService.handover(self).community
      elsif @responsibility_override.value == Responsibility::PRISON
        # Overrides to prison aren't actually possible in the UI
        # If they were, we'd somehow need to decide whether COM is supporting or not involved
        HandoverDateService::SUPPORTING
      else
        HandoverDateService::RESPONSIBLE
      end
    end

    def sentence_start_date
      sentence.sentence_start_date
    end

    def full_name
      "#{last_name}, #{first_name}".titleize
    end

    def full_name_ordered
      "#{first_name} #{last_name}".titleize
    end

    def responsibility_override?
      @responsibility_override.present?
    end

    # This list must only contain fields that are both supplied by
    # https://api-dev.prison.service.justice.gov.uk/swagger-ui.html#//prisoners/getPrisonersOffenderNo
    # and also by
    # https://api-dev.prison.service.justice.gov.uk/swagger-ui.html#//locations/getOffendersAtLocationDescription
    def initialize(api_payload, search_payload, latest_temp_movement:, complexity_level:)
      # It is expected that this method will be called by the subclass which
      # will have been given a payload at the class level, and will call this
      # method from it's own internal from_json
      @first_name = api_payload.fetch('firstName')
      @last_name = api_payload.fetch('lastName')
      @offender_no = api_payload.fetch('offenderNo')
      @convicted_status = api_payload['convictedStatus']
      @recall_flag = search_payload.fetch('recall', false)
      @sentence_type = SentenceType.new(api_payload['imprisonmentStatus'])
      @category_code = api_payload['categoryCode']
      @date_of_birth = Date.parse(api_payload.fetch('dateOfBirth'))
      @latest_temp_movement = latest_temp_movement
      @cell_location = search_payload['cellLocation']
      @complexity_level = complexity_level
    end

    def handover_start_date
      handover.start_date
    end

    def handover_reason
      handover.reason
    end

    def responsibility_handover_date
      handover.handover_date
    end

    def load_case_information(record)
      return if record.blank?

      # Hold on to the CaseInformation record so we can reference it later
      @case_information = record

      # This is separate from @case_information so the rest of this class doesn't need to know about the Active Record association
      @responsibility_override = record.responsibility
    end

    def approaching_handover?
      today = Time.zone.today
      thirty_days_time = today + 30.days

      start_date = handover_start_date
      handover_date = responsibility_handover_date

      return false if start_date.nil?

      if start_date.future?
        start_date.between?(today, thirty_days_time)
      else
        today.between?(start_date, handover_date)
      end
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

    def needs_a_com?
      (com_responsibility.responsible? || com_responsibility.supporting?) &&
        allocated_com_name.blank?
    end

    def inside_omic_policy?
      over_18? &&
        (sentenced? || immigration_case?) &&
        criminal_sentence? && convicted?
    end

    def category_label
      category_list = HmppsApi::PrisonApi::OffenderApi.get_category_labels
      category_list.fetch(@category_code, 'N/A')
    end

  private

    def age
      return nil if date_of_birth.blank?

      now = Time.zone.now

      if now.month == date_of_birth.month
        birthday_passed = now.day >= date_of_birth.day
      elsif now.month > date_of_birth.month
        birthday_passed = true
      end

      birth_years_ago = now.year - date_of_birth.year

      @age ||= birthday_passed ? birth_years_ago : birth_years_ago - 1
    end

    def criminal_sentence?
      @sentence_type.civil? == false
    end

    # Take either the new LocalDeliveryUnit (if available and enabled) and
    # fall back to the old local_divisional_unit if not. This should all go away
    # in Feb 2021 after the PDU changes have been rolled out in nDelius
    def ldu
      if @case_information&.local_delivery_unit&.enabled?
        @case_information.local_delivery_unit
      else
        @case_information&.local_divisional_unit
      end
    end

    def handover
      @handover ||= if pom_responsibility.responsible?
                      HandoverDateService.handover(self)
                    else
                      HandoverDateService::NO_HANDOVER_DATE
                    end
    end

    def early_allocation
      allocation = @case_information&.latest_early_allocation
      allocation if allocation.present? && (allocation.created_within_referral_window? && allocation.eligible? || allocation.community_decision?)
    end
  end
end
