# frozen_string_literal: true

module HmppsApi
  module PrisonApi
    class PrisonOffenderManagerApi
      extend PrisonApiClient

      def self.list(prison)
        route = "/staff/roles/#{prison}/role/POM"
        data = client.get(route, extra_headers: paging_options)
        api_deserialiser.deserialise_many(HmppsApi::PrisonOffenderManager, data)
      end

      # TODO: delete me.
      # This is just a helper method to obtain just one attribute
      # from the new API, but keeping it to avoid lots of refactoring
      # at this point. Will be cleaned up down the line.
      def self.fetch_email_addresses(nomis_staff_id)
        [HmppsApi::NomisUserRolesApi.staff_details(nomis_staff_id).email_address]
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
