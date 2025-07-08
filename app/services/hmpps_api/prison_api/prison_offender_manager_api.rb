# frozen_string_literal: true

module HmppsApi
  module PrisonApi
    class PrisonOffenderManagerApi
      extend PrisonApiClient

      def self.staff_detail(staff_id)
        route = "/staff/#{staff_id}"
        data = client.get(route)
        HmppsApi::StaffDetails.new data
      end

      def self.list(prison)
        route = "/staff/roles/#{prison}/role/POM"
        data = client.get(route, extra_headers: paging_options)
        api_deserialiser.deserialise_many(HmppsApi::PrisonOffenderManager, data)
      end

      def self.fetch_email_addresses(nomis_staff_id)
        route = "/staff/#{nomis_staff_id}/emails"
        data = client.get(route)

        return [] if data.blank?
        return JSON.parse(data) if data.is_a?(String)

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
