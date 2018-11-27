require "json"
require "faraday"

module Allocation
  class Api
    include Singleton

    def token
      @token ||= Nomis::Oauth::Api.instance.fetch_new_auth_token
    end

    def fetch_status
      endpoint = Rails.configuration.api_host.strip + "/status"
      response = Faraday.get do |req|
        req.url endpoint
        req.headers["Authorization"] = "Bearer #{token.encrypted_token}"
      end

      JSON.parse(response.body)
    end
  end
end
