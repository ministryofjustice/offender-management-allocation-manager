module Nomis
  module Custody
    ApiResponse = Struct.new(:data)
    ApiPaginatedResponse = Struct.new(:meta, :data)

    class Api
      include Singleton

      class << self
        delegate :fetch_nomis_staff_details, to: :instance
        delegate :get_offenders, to: :instance
        delegate :get_release_details, to: :instance
      end

      def initialize
        host = Rails.configuration.nomis_oauth_host
        @custodyapi_client = Nomis::Custody::Client.new(host)
      end

      def fetch_nomis_staff_details(username)
        route = "/custodyapi/api/nomis-staff-users/#{username}"
        response = @custodyapi_client.get(route)

        ApiResponse.new(api_deserialiser.deserialise(Nomis::StaffDetails, response))
      end

      # rubocop:disable Metrics/MethodLength
      def get_offenders(prison, page = 0)
        route = "/custodyapi/api/offenders/prison/#{prison}?page=#{page}&size=10"
        page_meta = nil

        response = @custodyapi_client.get(route) { |data|
          page_meta = api_deserialiser.deserialise(Nomis::PageMeta, data['page'])

          raise Nomis::Custody::Client::APIError, 'No data was returned' \
            unless data.key?('_embedded')
        }

        offenders = response['_embedded']['offenders'].map { |offender|
          api_deserialiser.deserialise(Nomis::OffenderDetails, offender)
        }

        ApiPaginatedResponse.new(page_meta, offenders)
      rescue Nomis::Custody::Client::APIError => e
        AllocationManager::ExceptionHandler.capture_exception(e)
        ApiPaginatedResponse.new(page_meta, [])
      end
      # rubocop:enable Metrics/MethodLength

      def get_release_details(offender_id, booking_id)
        # rubocop:disable Metrics/LineLength
        route = "/custodyapi/api/offenders/offenderId/#{offender_id}/releaseDetails?bookingId=#{booking_id}"
        # rubocop:enable Metrics/LineLength
        response = @custodyapi_client.get(route)
        ApiResponse.new(
          api_deserialiser.deserialise(Nomis::ReleaseDetails, response.first)
        )
      rescue Nomis::Custody::Client::APIError => e
        AllocationManager::ExceptionHandler.capture_exception(e)
        ApiResponse.new(NullReleaseDetails.new)
      end

    private

      def api_deserialiser
        @api_deserialiser ||= ApiDeserialiser.new
      end
    end
  end
end
