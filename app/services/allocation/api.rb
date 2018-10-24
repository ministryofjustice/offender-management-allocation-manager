require 'json'

module Allocation
  class Api
    include Singleton

    def fetch_status
      endpoint = Rails.configuration.api_host.strip + '/status'
      response = Faraday.get(endpoint)

      JSON.parse(response.body)
    end
  end
end
