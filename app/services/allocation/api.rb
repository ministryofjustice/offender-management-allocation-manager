require 'json'
require 'faraday'

module Allocation
  class Api
    include Singleton

    def token
      Nomis::Oauth::TokenService.instance.valid_token
    end

    def fetch_status
      endpoint = Rails.configuration.api_host.strip + '/status'
      response = Faraday.get { |req|
        req.url endpoint
        req.headers['Authorization'] = "Bearer #{token.access_token}"
      }

      JSON.parse(response.body)
    end
  end
end
