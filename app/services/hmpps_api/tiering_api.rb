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

      # it returns nil if an offender can't be found
    rescue Faraday::ResourceNotFound # 404 Not Found error
      nil
    rescue Faraday::ServerError
      { assessment_type: Faraday::ServerError, completed: nil }
    end
  end
end
