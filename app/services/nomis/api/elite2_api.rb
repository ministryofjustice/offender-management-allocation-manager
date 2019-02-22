module Nomis
  module Api
    ApiPaginatedResponse = Struct.new(:meta, :data)

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
