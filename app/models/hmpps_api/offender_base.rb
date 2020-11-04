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

    delegate :tier, :case_allocation, :crn, :mappa_level, :parole_review_date,
             to: :@case_information, allow_nil: true

    attr_accessor :category_code, :date_of_birth, :prison_arrival_date, :sentence, :allocated_pom_name

    attr_reader :first_name, :last_name, :booking_id, :offender_no, :sentence_type

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

      early_allocation = @case_information.latest_early_allocation
      early_allocation.present? && (early_allocation.eligible? || early_allocation.community_decision?)
    end

    # Has a CaseInformation record been loaded for this offender?
    def has_case_information?
      @case_information.present?
    end

    def nps_case?
      case_allocation == 'NPS'
    end

    def welsh_offender
      return nil if @case_information.blank?

      @case_information.welsh_offender == 'Yes'
    end

    def ldu
      @case_information&.local_divisional_unit
    end

    def team
      @case_information&.team&.name
    end

    def allocated_com_name
      @case_information&.com_name
    end

    def recalled?
      @recall_flag
    end

    def criminal_sentence?
      @sentence_type.civil? == false
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
        ResponsibilityService.calculate_pom_responsibility(self)
      elsif @responsibility_override.value == Responsibility::PRISON
        ResponsibilityService::RESPONSIBLE
      else
        ResponsibilityService::SUPPORTING
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

    def responsibility_override?
      @responsibility_override.present?
    end

    def load_from_json(payload)
      # It is expected that this method will be called by the subclass which
      # will have been given a payload at the class level, and will call this
      # method from it's own internal from_json
      @first_name = payload.fetch('firstName')
      @last_name = payload.fetch('lastName')
      @offender_no = payload.fetch('offenderNo')
      @convicted_status = payload['convictedStatus']
      @recall_flag = payload.fetch('recall')
      @sentence_type = SentenceType.new(payload['imprisonmentStatus'])
      @category_code = payload['categoryCode']
      @date_of_birth = deserialise_date(payload, 'dateOfBirth')
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

  private

    def handover
      @handover ||= if pom_responsibility.custody?
                      HandoverDateService.handover(self)
                    else
                      HandoverDateService::NO_HANDOVER_DATE
                    end
    end
  end
end
