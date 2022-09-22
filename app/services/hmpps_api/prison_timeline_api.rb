# frozen_string_literal: true

module HmppsApi
  class PrisonTimelineApi
    def self.client
      host = Rails.configuration.prison_api_host
      HmppsApi::Client.new("#{host}/api")
    end

    def self.get_prison_timeline(nomis_offender_id)
      safe_offender_no = URI.encode_www_form_component(nomis_offender_id)
      route = "/offenders/#{safe_offender_no}/prison-timeline"

      client.get(route)
    end
  end
end
