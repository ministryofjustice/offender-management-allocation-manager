require "json"
require "faraday"

module Allocation
  class Api
    include Singleton

    def initialize
      @token = nil
    end

    def fetch_status
      endpoint = Rails.configuration.api_host.strip + "/status"
      nomis_auth_token = check_auth_token
      response = Faraday.get do |req|
        req.url endpoint
        req.headers["Authorization"] = "Bearer #{nomis_auth_token}"
      end

      JSON.parse(response.body)
    end

  private

    def check_auth_token
      JWT.decode(
        @token,
        Rails.configuration.nomis_oauth_public_key,
        true,
        algorithm: 'RS256'
      )
    rescue JWT::ExpiredSignature
      fetch_auth_token
    end
  end
end
