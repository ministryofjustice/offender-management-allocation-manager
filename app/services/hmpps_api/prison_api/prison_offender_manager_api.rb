# frozen_string_literal: true

module HmppsApi
  module PrisonApi
    class PrisonOffenderManagerApi
      extend PrisonApiClient

      def self.list(prison, staff_id: nil)
        route, args = request_config(prison, staff_id:)
        data = client.get(route, **args)
        api_deserialiser.deserialise_many(HmppsApi::PrisonOffenderManager, data)
      end

      def self.expire_list_cache(prison)
        route, args = request_config(prison)
        client.expire_cache_key(:get, route, **args)
      end

    private

      def self.request_config(prison, staff_id: nil)
        [
          "/staff/roles/#{prison}/role/POM",
          {
            queryparams: { staffId: staff_id }.compact_blank,
            extra_headers: { 'Page-Limit' => '100', 'Page-Offset' => '0' }
          }
        ]
      end
    end
  end
end
