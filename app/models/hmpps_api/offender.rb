# frozen_string_literal: true

module HmppsApi
  class Offender
    include Deserialisable

    attr_reader :main_offence

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

    attr_accessor :prison_arrival_date, :sentence

    attr_reader :first_name, :last_name, :prison_id, :offender_no, :cell_location, :complexity_level, :date_of_birth

    # This list must only contain fields that are both supplied by
    # https://api-dev.prison.service.justice.gov.uk/swagger-ui.html#//prisoners/getPrisonersOffenderNo
    # and also by
    # https://api-dev.prison.service.justice.gov.uk/swagger-ui.html#//locations/getOffendersAtLocationDescription
    def initialize(api_payload, search_payload, category:, latest_temp_movement:, complexity_level:, booking_id:, prison_id:)
      # It is expected that this method will be called by the subclass which
      # will have been given a payload at the class level, and will call this
      # method from it's own internal from_json
      @first_name = api_payload.fetch('firstName')
      @last_name = api_payload.fetch('lastName')
      @offender_no = api_payload.fetch('offenderNo')
      @convicted_status = api_payload['convictedStatus']
      @date_of_birth = Date.parse(api_payload.fetch('dateOfBirth'))
      @latest_temp_movement = latest_temp_movement
      @cell_location = search_payload['cellLocation']
      @complexity_level = complexity_level
      @category = category

      @booking_id = booking_id
      @prison_id = prison_id
    end

    def load_main_offence
      @main_offence = HmppsApi::PrisonApi::OffenderApi.get_offence(@booking_id)
    end

    def get_image
      HmppsApi::PrisonApi::OffenderApi.get_image(@booking_id)
    end

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
        sentence.indeterminate_sentence?
    end

    def recalled?
      @sentence.recall
    end

    def over_18?
      age >= 18
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

    def inside_omic_policy?
      over_18? &&
        (sentenced? || immigration_case?) &&
        criminal_sentence? && convicted?
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
