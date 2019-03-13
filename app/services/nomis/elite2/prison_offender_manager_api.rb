require 'api_cache'

module Nomis
  module Elite2
    class PrisonOffenderManagerApi
      extend Elite2Api

      def self.list(prison)
        route = "/elite2api/api/staff/roles/#{prison}/role/POM"

        key = "pom_list_#{prison}"
        APICache.get(key, cache: 600, timeout: 30) {
          response = e2_client.get(route) { |data|
            raise Nomis::Client::APIError, 'No data was returned' if data.empty?
          }

          response.map { |pom|
            api_deserialiser.deserialise(Nomis::Models::PrisonOffenderManager, pom)
          }
        }
      end

      def self.fetch_email_addresses(nomis_staff_id)
        route = "/elite2api/api/staff/#{nomis_staff_id}/emails"
        data = e2_client.get(route)
        return [] if data.nil?

        data
      end
    end
  end
end
