module Nomis
  module Elite2
    class PrisonOffenderManagerApi
      extend Elite2Api

      def self.list(prison)
        route = "/elite2api/api/staff/roles/#{prison}/role/POM"

        key = "pom_list_#{prison}"

        data = Rails.cache.fetch(key, expires_in: 10.minutes) {
          e2_client.get(route) || []
        }

        data.map { |pom|
          api_deserialiser.deserialise(Nomis::Models::PrisonOffenderManager, pom)
        }
      end
    end
  end
end
