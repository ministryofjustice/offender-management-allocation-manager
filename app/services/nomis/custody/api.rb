module Nomis
  module Custody
    ApiResponse = Struct.new(:data)
    ApiPaginatedResponse = Struct.new(:meta, :data)

    class Api
      include Singleton

      class << self
        delegate :fetch_nomis_staff_details, to: :instance
      end

      def initialize
        host = Rails.configuration.nomis_oauth_host
        @custodyapi_client = Nomis::Client.new(host)
      end

      def fetch_nomis_staff_details(username)
        route = "/custodyapi/api/nomis-staff-users/#{username}"
        response = @custodyapi_client.get(route)

        ApiResponse.new(api_deserialiser.deserialise(Nomis::StaffDetails, response))
      end

    private

      def api_deserialiser
        @api_deserialiser ||= ApiDeserialiser.new
      end
    end
  end
end
