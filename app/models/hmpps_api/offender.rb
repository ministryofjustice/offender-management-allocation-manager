# frozen_string_literal: true

module HmppsApi
  class Offender < OffenderBase
    include Deserialisable

    attr_accessor :main_offence

    attr_reader :prison_id

    def self.from_json(payload, recall_flag:, latest_temp_movement:)
      Offender.new(payload, recall_flag: recall_flag, latest_temp_movement: latest_temp_movement)
    end

    # This must only reference fields that are present in
    # https://https://api-dev.prison.service.justice.gov.uk/swagger-ui.html#//prisoners/getPrisonersOffenderNo
    def initialize(payload, recall_flag:, latest_temp_movement:)
      @booking_id = payload['latestBookingId']&.to_i
      @prison_id = payload['latestLocationId']

      super(payload, recall_flag: recall_flag, latest_temp_movement: latest_temp_movement)
    end
  end
end
