# frozen_string_literal: true

module Nomis
  module Elite2
    class PrisonOffenderManagerApi
      extend Elite2Api

      def self.staff_detail(staff_id)
        route = "/elite2api/api/staff/#{staff_id}"
        data = e2_client.get(route)
        api_deserialiser.deserialise(Nomis::StaffDetails, data)
      end

      def self.list(prison)
        route = "/elite2api/api/staff/roles/#{prison}/role/POM"

        key = "pom_list_#{prison}"

        data = Rails.cache.fetch(key, expires_in: Rails.configuration.cache_expiry) {
          e2_client.get(route,  extra_headers: paging_options { |result|
            raise Nomis::Client::APIError, 'No data was returned' if result.empty?
          })
        }

        api_deserialiser.deserialise_many(Nomis::PrisonOffenderManager, data)
      end

      def self.fetch_email_addresses(nomis_staff_id)
        route = "/elite2api/api/staff/#{nomis_staff_id}/emails"
        data = e2_client.get(route)
        return [] if data.nil?

        data
      end

    private

      def self.paging_options
        {
          'Page-Limit' => '100',
          'Page-Offset' => '0'
        }
      end
    end
  end
end
