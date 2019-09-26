# frozen_string_literal: true

module Nomis
  class Offender < OffenderBase
    include Deserialisable

    delegate :home_detention_curfew_eligibility_date,
             :conditional_release_date, :release_date,
             :parole_eligibility_date, :tariff_date,
             :automatic_release_date,
             to: :sentence

    attr_accessor :gender,
                  :latest_booking_id,
                  :main_offence,
                  :nationalities,
                  :noms_id,
                  :reception_date,
                  :latest_location_id

    def initialize(fields = nil)
      # Allow this object to be reconstituted from a hash, we can't use
      # from_json as the one passed in will already be using the snake case
      # names whereas from_json is expecting the elite2 camelcase names.
      fields.each { |k, v| instance_variable_set("@#{k}", v) } if fields.present?
    end

    def early_allocation?
      false
    end

    def nps_case?
      case_allocation == 'NPS'
    end

    def self.from_json(payload)
      Offender.new.tap { |obj|
        obj.load_from_json(payload)
      }
    end

    def load_from_json(payload)
      @gender = payload['gender']
      @latest_booking_id = payload['latestBookingId']&.to_i
      @main_offence = payload['mainOffence']
      @nationalities = payload['nationalities']
      @noms_id = payload['nomsId']
      @latest_location_id = payload['latestLocationId']
      @reception_date = deserialise_date(payload, 'receptionDate')

      super(payload)
    end
  end
end
