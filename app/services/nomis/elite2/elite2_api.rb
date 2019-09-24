# frozen_string_literal: true

module Nomis
  module Elite2
    ApiPaginatedResponse = Struct.new(:total_pages, :data)

    module Elite2Api
      def e2_client
        host = Rails.configuration.nomis_oauth_host
        Nomis::Client.new(host)
      end

      def api_deserialiser
        ApiDeserialiser.new
      end
    end
  end
end
