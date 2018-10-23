require 'json'

module Allocation
  class Api
    include Singleton

    def fetch_status
      endpoint = CGI.escape(Rails.configuration.api_host)
      url = URI.parse(endpoint)
      response = Faraday.get(url)

      JSON.parse(response.body)
    end
  end
end
