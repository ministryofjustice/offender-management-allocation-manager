# frozen_string_literal: true

module HmppsApi
  module Oauth
    class Client
      include ClientHelper

      def initialize(host)
        @host = host
        @connection = Faraday.new do |faraday|
          faraday.request :retry, max: 3, interval: 0.05,
                                  interval_randomness: 0.5, backoff_factor: 2,
                                  # We appear to get occasional transient 5xx errors, so retry them
                                  retry_statuses: [500, 502],
                                  methods: Faraday::Request::Retry::IDEMPOTENT_METHODS + [:post]

          faraday.response :raise_error
        end
        @connection.basic_auth(Rails.configuration.hmpps_api_client_id, Rails.configuration.hmpps_api_client_secret)
      end

      def post(route)
        request(:post, route)
      end

    private

      def request(method, route)
        response = @connection.send(method) do |req|
          url = URI.join(@host, route).to_s
          req.url(url)
        end

        JSON.parse(response.body)
      end
    end
  end
end
