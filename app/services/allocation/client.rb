require 'faraday'

module Allocation
  class Client
    def initialize(host)
      @host = host
      @connection = Faraday.new
    end

    def get(route)
      request(:get, route)
    end

  private

    def request(method, route)
      response = @connection.send(method) { |req|
        req.url(@host + route)
        req.headers['Authorization'] = "Bearer #{token.access_token}"
      }

      JSON.parse(response.body)
    end

    def token
      Nomis::Oauth::TokenService.valid_token
    end
  end
end
