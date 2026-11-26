# frozen_string_literal: true

require 'faraday'
require 'faraday/retry'

module HmppsApi
  module Oauth
    class Client
      include ClientHelper

      def initialize(host)
        @host = host
        @connection = Faraday.new do |faraday|
          faraday.options.open_timeout = Rails.configuration.hmpps_api_open_timeout_seconds
          faraday.options.timeout = Rails.configuration.hmpps_api_timeout_seconds

          faraday.response :raise_error
          faraday.request(
            :retry,
            max: 3, interval: 0.05, interval_randomness: 0.5, backoff_factor: 2, max_interval: 5,
            retry_statuses: [502],
            methods: Faraday::Retry::Middleware::IDEMPOTENT_METHODS + [:post],
            retry_block: lambda { |env:, retry_count:, exception:, **|
              log_retry(env, retry_count, exception)
            },
          )

          faraday.request :authorization, :basic,
                          Rails.configuration.hmpps_api_client_id,
                          Rails.configuration.hmpps_api_client_secret

          faraday.response :raise_error, allowed_statuses: [502]
          faraday.adapter :net_http
        end
      end

      def get(route)
        request(:get, route)
      end

      def post(route)
        request(:post, route)
      end

      def request(method, route)
        response = @connection.send(method) do |req|
          url = URI.join(@host, route).to_s
          req.url(url)
        end

        JSON.parse(response.body)
      rescue Faraday::Error => e
        Rails.logger.warn(
          "event=hmpps_oauth_request_failed,reason=#{e.class},method=#{method.to_s.upcase},route=#{URI.parse(route).path}," \
          "status=#{e.response_status}"
        )
        raise
      end

    private

      def log_retry(env, retry_count, exception)
        status = exception.respond_to?(:response_status) ? exception.response_status : nil
        Rails.logger.warn(
          "event=hmpps_oauth_retry,reason=#{exception.class},method=#{env.method.to_s.upcase},route=#{env.url.path}," \
          "status=#{status},retry_count=#{retry_count}"
        )
      end
    end
  end
end
