module HmppsApi
  class AssessRisksAndNeedsApi
    VALID_ASSESSMENT_TYPES = %w[LAYER_1 LAYER_3].freeze

    def self.client
      host = Rails.configuration.assess_risks_and_needs_api_host
      HmppsApi::Client.new(host)
    end

    def self.get_rosh_summary(crn)
      safe_crn = URI.encode_www_form_component(crn)
      route = "/risks/crn/#{safe_crn}"
      client.get(route)
    end

    def self.get_latest_oasys_date(nomis_id)
      safe_nomis = URI.encode_www_form_component(nomis_id)
      route = "/assessments/timeline/nomisId/#{safe_nomis}"
      response = client.get(route)

      assessment = response['timeline'].select { |a|
        VALID_ASSESSMENT_TYPES.include?(a.fetch('assessmentType')) &&
          a.fetch('status') == 'COMPLETE'
      }.max { |a, b| a.fetch('completedDate') <=> b.fetch('completedDate') }

      return nil if assessment.nil?

      {
        assessment_type: assessment.fetch('assessmentType'),
        completed: assessment.fetch('completedDate').to_date
      }
    rescue Faraday::ResourceNotFound # 404 Not Found error
      nil
    rescue Faraday::ConflictError # 409 Duplicate record found on oasys. Needs merging oasys to process correctly
      { assessment_type: Faraday::ConflictError, completed: nil }
    rescue Faraday::ServerError
      { assessment_type: Faraday::ServerError, completed: nil }
    end
  end
end
