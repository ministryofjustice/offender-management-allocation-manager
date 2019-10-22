# frozen_string_literal: true

module Nomis
  class OffenderSummary < OffenderBase
    include Deserialisable

    attr_accessor :aliases

    # custom attributes
    attr_accessor :allocation_date, :prison_arrival_date

    attr_reader :prison_id

    def awaiting_allocation_for
      (Time.zone.today - prison_arrival_date).to_i
    end

    def self.from_json(payload)
      OffenderSummary.new.tap { |obj|
        obj.load_from_json(payload)
      }
    end

    def load_from_json(payload)
      @aliases = payload['aliases']
      @booking_id = payload['bookingId']&.to_i
      @prison_id = payload['agencyId']

      super(payload)
    end
  end
end
