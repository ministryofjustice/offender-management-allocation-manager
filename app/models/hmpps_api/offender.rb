# frozen_string_literal: true

module HmppsApi
  class Offender < OffenderBase
    include Deserialisable

    attr_accessor :main_offence

    attr_reader :prison_id

    # This must only reference fields that are present in
    # https://https://api-dev.prison.service.justice.gov.uk/swagger-ui.html#//prisoners/getPrisonersOffenderNo
    def initialize(api_payload, search_payload, latest_temp_movement:, complexity_level:)
      @booking_id = api_payload['latestBookingId']&.to_i
      @prison_id = api_payload['latestLocationId']

      super(api_payload, search_payload, latest_temp_movement: latest_temp_movement, complexity_level: complexity_level)
    end
  end
end
