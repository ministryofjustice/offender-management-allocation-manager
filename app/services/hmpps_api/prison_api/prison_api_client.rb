# frozen_string_literal: true

module HmppsApi
  module PrisonApi
    ApiPaginatedResponse = Struct.new(:total_pages, :data)

    module PrisonApiClient
      def e2_client
        host = Rails.configuration.prison_api_host
        HmppsApi::Client.new(host + '/api')
      end

      def search_client
        host = Rails.configuration.prisoner_search_host
        HmppsApi::Client.new(host + '/prisoner-search')
      end

      def api_deserialiser
        ApiDeserialiser.new
      end
    end
  end
end
