# frozen_string_literal: true

module HmppsApi
  class OffenderSummary < OffenderBase
    include Deserialisable

    attr_accessor :allocation_date

    attr_reader :prison_id, :facial_image_id

    def awaiting_allocation_for
      (Time.zone.today - prison_arrival_date).to_i
    end

    def case_owner
      if pom_responsibility.responsible?
        'Custody'
      else
        'Community'
      end
    end

    def self.from_json(api_payload, search_payload, latest_temp_movement:)
      OffenderSummary.new(api_payload, search_payload, latest_temp_movement: latest_temp_movement)
    end

    # This list must only contain values that are returned by
    # https://api-dev.prison.service.justice.gov.uk/swagger-ui.html#//locations/getOffendersAtLocationDescription
    def initialize(api_payload, search_payload, latest_temp_movement:)
      @booking_id = api_payload.fetch('bookingId').to_i
      @prison_id = api_payload.fetch('agencyId')
      @facial_image_id = api_payload['facialImageId']&.to_i

      super(api_payload, search_payload, latest_temp_movement: latest_temp_movement)
    end
  end
end
