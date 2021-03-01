# frozen_string_literal: true

module HmppsApi
  class Offender < OffenderBase
    include Deserialisable

    attr_accessor :main_offence

    attr_reader :prison_id

    def initialize(fields = {})
      # Allow this object to be reconstituted from a hash, we can't use
      # from_json as the one passed in will already be using the snake case
      # names whereas from_json is expecting the elite2 camelcase names.
      fields.each do |k, v|
        instance_variable_set("@#{k}", v)
      end
    end

    def self.from_json(payload)
      Offender.new.tap { |obj|
        obj.load_from_json(payload)
      }
    end

    # This must only reference fields that are present in
    # https://https://api-dev.prison.service.justice.gov.uk/swagger-ui.html#//prisoners/getPrisonersOffenderNo
    def load_from_json(payload)
      @booking_id = payload['latestBookingId']&.to_i
      @prison_id = payload['latestLocationId']

      super(payload)
    end
  end
end
