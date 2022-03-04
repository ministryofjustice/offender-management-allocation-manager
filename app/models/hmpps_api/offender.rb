# frozen_string_literal: true

module HmppsApi
  class Offender
    def awaiting_allocation_for
      (Time.zone.today - prison_arrival_date).to_i
    end

    delegate :home_detention_curfew_eligibility_date,
             :home_detention_curfew_actual_date,
             :conditional_release_date, :release_date,
             :parole_eligibility_date, :tariff_date,
             :automatic_release_date, :licence_expiry_date,
             :post_recall_release_date, :earliest_release_date,
             :indeterminate_sentence?, :immigration_case?, :civil_sentence?, :describe_sentence,
             to: :sentence

    delegate :code, :label, :active_since, to: :@category, prefix: :category, allow_nil: true

    attr_accessor :prison_arrival_date

    attr_reader :first_name, :last_name, :prison_id, :offender_no, :location, :complexity_level,
                :date_of_birth, :sentence, :main_offence

    def initialize(offender:, category:, latest_temp_movement:, complexity_level:)
      restricted_patient = offender['restrictedPatient'] == true
      @first_name = offender.fetch('firstName')
      @last_name = offender.fetch('lastName')
      @offender_no = offender.fetch('prisonerNumber')
      @date_of_birth = offender.fetch('dateOfBirth').to_date
      @latest_temp_movement = latest_temp_movement
      @location = restricted_patient ? offender['dischargedHospitalDescription'] : offender['cellLocation']
      @main_offence = offender['mostSeriousOffence']
      @complexity_level = complexity_level
      @category = category
      @sentence = HmppsApi::SentenceDetail.new(offender)
      @booking_id = offender.fetch('bookingId').to_i
      @prison_id = restricted_patient ? offender.fetch('supportingPrisonId') : offender.fetch('prisonId')
      @restricted_patient = restricted_patient
    end

    def get_image
      HmppsApi::PrisonApi::OffenderApi.get_image(@booking_id)
    end

    def latest_temp_movement_date
      @latest_temp_movement&.movement_date
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
        sentence.indeterminate_sentence?
    end

    def recalled?
      @sentence.recall
    end

    def over_18?
      age >= 18
    end

    def restricted_patient?
      @restricted_patient == true
    end

    delegate :sentence_start_date, to: :sentence

    def full_name
      "#{last_name}, #{first_name}".titleize
    end

    def full_name_ordered
      "#{first_name} #{last_name}".titleize
    end

    def inside_omic_policy?
      over_18? &&
        (sentenced? || immigration_case?) &&
        criminal_sentence?
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
      @sentence.criminal_sentence?
    end
  end
end
