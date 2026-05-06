module HmppsApi
  class PrisonAlertsApi
    def self.client
      host = Rails.configuration.prison_alerts_api_host
      HmppsApi::Client.new(host)
    end

    # See: https://alerts-api-dev.hmpps.service.justice.gov.uk/swagger-ui/index.html#/RO%20Operations/retrievePrisonerAlerts_1
    def self.alerts_for(nomis_offender_id)
      safe_offender_no = URI.encode_www_form_component(nomis_offender_id)
      route = "/prisoners/#{safe_offender_no}/alerts"
      data, = client.get(route)

      raise TypeError, 'unexpected response body' unless data.is_a?(Hash)

      data.fetch('content', [])
    rescue Faraday::Error, JSON::ParserError, TypeError => e
      Rails.logger.error("event=prison_alerts_api_error,nomis_offender_id=#{nomis_offender_id}|#{e.message}")
      nil
    end
  end
end
