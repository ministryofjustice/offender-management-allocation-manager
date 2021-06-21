# frozen_string_literal: true

module HmppsApi
  module PrisonApi
    ApiPaginatedResponse = Struct.new(:total_pages, :data)

    module PrisonApiClient
      # Client for the Prison API
      def client
        host = Rails.configuration.prison_api_host
        # Prison API uses POSTs as fake GETs so its ok to retry them
        HmppsApi::Client.new(host + '/api', extra_retry_methods: [:post])
      end

      # Client for the Prisoner Offender Search API
      def search_client
        host = Rails.configuration.prisoner_search_host
        # Prison Search API uses POSTs as fake GETs so its ok to retry them
        HmppsApi::Client.new(host + '/prisoner-search', extra_retry_methods: [:post])
      end

      def api_deserialiser
        ApiDeserialiser.new
      end
    end
  end
end
