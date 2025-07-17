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
