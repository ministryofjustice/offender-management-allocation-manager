require 'json'

module Allocation
  class Api
    include Singleton

    def fetch_status
      response = Faraday.get(Rails.configuration.api_host)

      JSON.parse(response.body)
    end
  end
end
