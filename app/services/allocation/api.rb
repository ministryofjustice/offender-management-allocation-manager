require "json"
require "faraday"

module Allocation
  class Api
    include Singleton

    def fetch_status
      endpoint = Rails.configuration.api_host.strip + "/status"
      response = Faraday.get(endpoint)

      JSON.parse(response.body)
    end

    # TODO: Fetching auth token should not be part of this api

    def fetch_auth_token
      response = Faraday.post do |req|
        req.url "#{Rails.configuration.nomis_oauth_url}/auth/oauth/token?grant_type=client_credentials"
        req.headers["Authorization"] = "Basic #{Rails.configuration.nomis_oauth_authorisation}"
      end

      response_body = JSON.parse(response.body)

      Nomis::Token.new(response_body)
    end
  end
end

module Nomis
  class Token
    attr_reader :type, :expiry, :access_token

    def initialize(payload)
      @type = payload['token_type']
      @expiry = payload['expires_in']
      @access_token = payload['access_token']
    end
  end
end
