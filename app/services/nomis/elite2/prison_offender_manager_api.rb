require 'api_cache'

module Nomis
  module Elite2
    class PrisonOffenderManagerApi
      extend Elite2Api

      def self.list(prison)
        route = "/elite2api/api/staff/roles/#{prison}/role/POM"

        key = "pom_list_#{prison}"
        response = APICache.get(key, cache: 600) {
          response = e2_client.get(route) { |data|
            raise Nomis::Elite2::Client::APIError, 'No data was returned' if data.empty?
          }

          response.map { |pom|
            api_deserialiser.deserialise(Nomis::Models::PrisonOffenderManager, pom)
          }
        }
      end
    end
  end
end
