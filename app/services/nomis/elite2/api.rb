module Nomis
  module Elite2
    ApiResponse = Struct.new(:data)
    ApiPaginatedResponse = Struct.new(:meta, :data)

    class Api
      include Singleton

      class << self
        delegate :test_stub, to: :instance
      end

      def initialize
        host = Rails.configuration.nomis_oauth_host
        @e2_client = Nomis::Client.new(host)
      end

      def test_stub
        _route = '/elite2api/api/'
        _deserializer = api_deserialiser
        ApiResponse.new(nil)
      end

    private

      def api_deserialiser
        @api_deserialiser ||= ApiDeserialiser.new
      end
    end
  end
end
