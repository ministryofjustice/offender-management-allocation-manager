module Nomis
  module Custody
    class Api
      include Singleton

      class << self
        delegate :fetch_nomis_staff_details, to: :instance
        delegate :get_offenders, to: :instance
      end

      def initialize
        host = Rails.configuration.nomis_oauth_host
        @custodyapi_client = Nomis::Custody::Client.new(host)
      end

      def fetch_nomis_staff_details(username)
        route = "/custodyapi/api/nomis-staff-users/#{username}"
        response = @custodyapi_client.get(route)
        api_deserialiser.deserialise(Nomis::StaffDetails, response)
      end

      def get_offenders(prison)
        route = "/custodyapi/api/offenders/prison/#{prison}?page=1&size=10"
        response = @custodyapi_client.get(route)
        response['_embedded']['offenders'].map do |offender|
          api_deserialiser.deserialise(Nomis::OffenderDetails, offender)
        end
      end

    private

      def api_deserialiser
        @api_deserialiser ||= ApiDeserialiser.new
      end
    end
  end
end
