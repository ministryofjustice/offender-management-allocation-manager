module Nomis
  module Elite2
    class PrisonOffenderManagerApi
      extend Elite2Api

      def self.list(prison)
        route = "/elite2api/api/staff/roles/#{prison}/role/POM"

        key = "pom_list_#{prison}"

        data = Rails.cache.fetch(key, expires_in: 10.minutes) {
          e2_client.get(route) { |result|
            raise Nomis::Client::APIError, 'No data was returned' if result.empty?
          }
        }

        data.map { |pom|
          api_deserialiser.deserialise(Nomis::Models::PrisonOffenderManager, pom)
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
