# frozen_string_literal: true

module Nomis
  class Offender < OffenderBase
    include Deserialisable

    attr_accessor :main_offence

    attr_reader :reception_date, :prison_id

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

    def load_from_json(payload)
      @booking_id = payload.fetch('latestBookingId').to_i
      @prison_id = payload['latestLocationId']
      @reception_date = deserialise_date(payload, 'receptionDate')

      super(payload)
    end
  end
end
