module HmppsApi
  class TieringApi
    def self.client
      host = Rails.configuration.tiering_api_host
      HmppsApi::Client.new(host)
    end

    def self.get_calculation(crn, calculation_id)
      safe_crn = URI.encode_www_form_component(crn)
      safe_calculation_id = URI.encode_www_form_component(calculation_id)
      route = "/crn/#{safe_crn}/tier/#{safe_calculation_id}"
      response = client.get(route)

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
