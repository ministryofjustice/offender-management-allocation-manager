module HmppsApi
  class AssessRisksAndNeedsApi
    def self.client
      host = Rails.configuration.assess_risks_and_needs_api_host
      HmppsApi::Client.new(host)
    end

    def self.get_rosh_summary(crn)
      safe_crn = URI.encode_www_form_component(crn)
      route = "/risks/crn/#{safe_crn}/summary"
      client.get(route)
    end
  end
end
