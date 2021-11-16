module HmppsApi
  class AssessmentApi
    VALID_ASSESSMENT_TYPES = %w[LAYER_1 LAYER_3].freeze
    def self.client
      host = Rails.configuration.assessment_api_host
      HmppsApi::Client.new(host)
    end

    def self.get_latest_oasys_date(offender_no)
      safe_offender_no = URI.encode_www_form_component(offender_no)
      route = "/offenders/nomisId/#{safe_offender_no}/assessments/summary?assessmentStatus=COMPLETE"

      assessment = self.client.get(route).select { |a| a.fetch('assessmentType', nil).in? VALID_ASSESSMENT_TYPES }
                       .max_by { |a| [a.fetch('assessmentType'), a.fetch('completed')] }

      unless assessment.nil?
        {
          assessment_type: assessment.fetch('assessmentType'),
          completed: assessment.fetch('completed').to_date
        }
      end

      # it returns nil if an offender can't be found
    rescue Faraday::ResourceNotFound # 404 Not Found error
      nil
    rescue Faraday::ConflictError # 409 Duplicate record found on oasys. Needs merging oasys to process correctly
      { assessment_type: Faraday::ConflictError, completed: nil }
    end
  end
end
