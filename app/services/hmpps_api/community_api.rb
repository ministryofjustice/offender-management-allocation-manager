# frozen_string_literal: true

module HmppsApi
  class CommunityApi
    def self.client
      host = Rails.configuration.community_api_host
      HmppsApi::Client.new(host + '/secure')
    end

    def self.set_pom(offender_no:, prison:, forename:, surname:)
      safe_offender_no = URI.encode_www_form_component(offender_no)
      route = "/offenders/nomsNumber/#{safe_offender_no}/prisonOffenderManager"

      body = {
        nomsPrisonInstitutionCode: prison,
        officer: {
          forenames: forename,
          surname: surname
        }
      }

      # We don't use a cache here because we're not 'getting' data, but 'pushing' it
      self.client.put(route, body)

      # So long as the API call didn't error, return true
      # The API response body isn't useful to us
      true
    end

    def self.set_handover_dates(offender_no:, handover_start_date:, responsibility_handover_date:)
      safe_offender_no = URI.encode_www_form_component(offender_no)
      base_route = "/offenders/nomsNumber/#{safe_offender_no}/custody/keyDates/"

      # Map dates to the correct `{typeCode}` for the Community API
      dates = {
        POM1: handover_start_date,
        POM2: responsibility_handover_date
      }

      dates.stringify_keys.each do |code, date|
        route = base_route + code
        body = { date: date.strftime('%F') }
        self.client.put(route, body)
      end

      # So long as the API calls didn't error, return true
      # The API response bodies aren't useful to us
      true
    end
  end
end
