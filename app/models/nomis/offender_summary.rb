# frozen_string_literal: true

module Nomis
  class OffenderSummary < OffenderBase
    include Deserialisable

    attr_accessor :agency_id, :aliases, :booking_id

    # custom attributes
    attr_accessor :allocation_date

    def self.from_json(payload)
      OffenderSummary.new.tap { |obj|
        obj.load_from_json(payload)
      }
    end

    def load_from_json(payload)
      @agency_id = payload['agencyId']
      @aliases = payload['aliases']
      @booking_id = payload['bookingId']&.to_i

      super(payload)
    end
  end
end
