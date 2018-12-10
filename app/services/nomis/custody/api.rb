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
        @custodyapi_client.get(route)
      end

      def get_offenders(prison)
        route = "/custodyapi/api/offenders/prison/#{prison}?page=1&size=10"
        response = @custodyapi_client.get(route)
        response['_embedded']['offenders']
      end
    end
  end
end
