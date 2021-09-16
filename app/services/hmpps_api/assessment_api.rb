module HmppsApi
  class AssessmentApi
    def self.client
      host = Rails.configuration.assessment_api_host
      HmppsApi::Client.new(host)
    end

    def self.get_latest_oasys_date(offender_no)
      safe_offender_no = URI.encode_www_form_component(offender_no)
      route = "/offenders/nomisId/#{safe_offender_no}/assessments/summary?assessmentType=LAYER_3&assessmentStatus=COMPLETE"

      all_assessments = self.client.get(route)

      # it returns the latest assessment date or nil if there are none
      all_assessments.map { |assessment| assessment.fetch('completed').to_date }.max

      # it returns nil if an offender can't be found
    rescue Faraday::ResourceNotFound # 404 Not Found error
      nil
    end
  end
end
