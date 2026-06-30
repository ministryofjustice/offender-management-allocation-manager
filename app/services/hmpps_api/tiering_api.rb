module HmppsApi
  class TieringApi
    def self.client
      host = Rails.configuration.tiering_api_host
      HmppsApi::Client.new(host)
    end

    # NOTE: cache is disabled because the `calculation_id` are unique UUIDs
    # that never get reused, so is wasteful to be caching these responses
    def self.get_calculation(crn, calculation_id, version:)
      route = "/v#{version}/crn/#{crn}/tier/#{calculation_id}"
      response = client.get(route, cache: false)

      {
        tier: response.fetch('tierScore'),
        calculation_date: response.fetch('calculationDate').to_date
      }
    rescue Faraday::Error => e
      Rails.logger.error("event=tiering_get_calculation,route=#{route}|#{e.message}")

      # it returns 404 if a calculation can't be found
      return nil if e.is_a?(Faraday::ResourceNotFound)

      { tier: nil, calculation_date: nil, error: e.class }
    end
  end
end
