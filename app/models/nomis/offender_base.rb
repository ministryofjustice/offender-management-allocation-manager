module Nomis
  class OffenderBase
    attr_accessor :first_name,
                  :last_name,
                  :date_of_birth,
                  :offender_no,
                  :convicted_status,
                  :imprisonment_status,
                  :category_code

    # Custom attributes
    attr_accessor :crn,
                  :allocated_pom_name, :case_allocation,
                  :omicable, :tier,
                  :sentence, :mappa_level,
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
      SentenceTypeService.indeterminate_sentence?(imprisonment_status)
    end

    def recalled?
      SentenceTypeService.recall_sentence?(imprisonment_status)
    end

    def over_18?
      age >= 18
    end

    def awaiting_allocation_for
      omic_start_date = Date.new(2019, 2, 4)

      if sentence.sentence_start_date.nil? ||
          sentence.sentence_start_date < omic_start_date
        (Time.zone.today - omic_start_date).to_i
      else
        (Time.zone.today - sentence.sentence_start_date).to_i
      end
    end

    def case_owner
      pom_responsibility = ResponsibilityService.new.calculate_pom_responsibility(self)
      return 'Prison' if pom_responsibility == ResponsibilityService::RESPONSIBLE

      'Probation'
    end

    def earliest_release_date
      sentence.earliest_release_date
    end

    def full_name
      "#{last_name}, #{first_name}".titleize
    end

    def full_name_ordered
      "#{first_name} #{last_name}".titleize
    end

    # rubocop:disable Rails/Date
    def age
      @age ||= ((Time.zone.now - date_of_birth.to_time) / 1.year.seconds).floor
    end
    # rubocop:enable Rails/Date

    def load_from_json(payload)
      # It is expected that this method will be called by the subclass which
      # will have been given a payload at the class level, and will call this
      # method from it's own internal from_json
      @first_name = payload['firstName']
      @last_name = payload['lastName']
      @offender_no = payload['offenderNo']
      @convicted_status = payload['convictedStatus']
      @imprisonment_status = payload['imprisonmentStatus']
      @category_code = payload['categoryCode']
      @date_of_birth = deserialise_date(payload, 'dateOfBirth')
    end

    def handover_start_date
      HandoverDateService.handover_start_date(self)
    end

    def responsibility_handover_date
      HandoverDateService.responsibility_handover_date(self)
    end
  end
end
