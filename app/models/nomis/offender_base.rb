module Nomis
  class OffenderBase
    delegate :home_detention_curfew_eligibility_date,
             :post_recall_release_date, :post_recall_release_override_date,
             :home_detention_curfew_actual_date,
             :conditional_release_date, :release_date,
             :parole_eligibility_date, :tariff_date,
             :automatic_release_date,
             to: :sentence

    attr_accessor :convicted_status, :booking_id,
                  :category_code, :offender_no, :date_of_birth,
                  :first_name, :last_name

    # Custom attributes
    attr_accessor :crn,
                  :allocated_pom_name, :case_allocation,
                  :allocated_com_name,
                  :welsh_offender, :tier, :parole_review_date,
                  :sentence, :mappa_level, :probation_service,
                  :ldu, :team

    def convicted?
      convicted_status == 'Convicted'
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
      @early_allocation
    end

    def nps_case?
      case_allocation == 'NPS'
    end

    def sentence_type_code
      @sentence_type.code
    end

    # sentence type may be nil if we are created as a stub
    def recalled?
      @sentence_type.try(:recall_sentence?)
    end

    def indeterminate_sentence?
      @sentence_type.try(:indeterminate_sentence?)
    end

    def criminal_sentence?
      @sentence_type.civil? == false
    end

    def civil_sentence?
      @sentence_type.civil?
    end

    def describe_sentence
      @sentence_type.description
    end

    def over_18?
      age >= 18
    end

    def immigration_case?
      sentence_type_code == 'DET'
    end

    def earliest_release_date
      sentence.earliest_release_date
    end

    def pom_responsibility
      ResponsibilityService.calculate_pom_responsibility(self)
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

    def load_from_json(payload)
      # It is expected that this method will be called by the subclass which
      # will have been given a payload at the class level, and will call this
      # method from it's own internal from_json
      @first_name = payload['firstName']
      @last_name = payload['lastName']
      @offender_no = payload['offenderNo']
      @convicted_status = payload['convictedStatus']
      @sentence_type = SentenceType.new(payload['imprisonmentStatus'])
      @category_code = payload['categoryCode']
      @date_of_birth = deserialise_date(payload, 'dateOfBirth')
      @early_allocation = false
    end

    def inprisonment_status=(status)
      @sentence_type = SentenceType.new(status)
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

      @tier = record.tier
      @case_allocation = record.case_allocation
      @welsh_offender = record.welsh_offender == 'Yes'
      @probation_service = record.probation_service
      @crn = record.crn
      @mappa_level = record.mappa_level
      @ldu = record.local_divisional_unit
      @team = record.team.try(:name)
      @parole_review_date = record.parole_review_date
      @early_allocation = record.latest_early_allocation.present? &&
        (record.latest_early_allocation.eligible? || record.latest_early_allocation.community_decision?)
    end

  private

    def handover
      @handover ||= HandoverDateService.handover(self)
    end
  end
end
