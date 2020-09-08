# frozen_string_literal: true

module Nomis
  module Elite2
    ApiPaginatedResponse = Struct.new(:total_pages, :data)

    module Elite2Api
      def e2_client
        host = Rails.configuration.prison_api_host
        Nomis::Client.new(host + '/api')
      end

      def search_client
        host = Rails.configuration.prisoner_search_host
        Nomis::Client.new(host + '/prisoner-search')
      end

      def api_deserialiser
        ApiDeserialiser.new
      end
    end
  end
end
