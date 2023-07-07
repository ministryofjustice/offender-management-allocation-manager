# frozen_string_literal: true

module HmppsApi
  class CommunityApi
    class KeyDate
      # These are `{typeCode}` values for 'key dates' in the Community API
      #
      HANDOVER_START_DATE = 'POM1'
      RESPONSIBILITY_HANDOVER_DATE = 'POM2'
    end

    def self.client
      host = Rails.configuration.community_api_host
      HmppsApi::Client.new("#{host}/secure")
    end

    def self.get_offender(nomis_offender_id)
      safe_offender_no = URI.encode_www_form_component(nomis_offender_id)
      route = "/offenders/nomsNumber/#{safe_offender_no}/all"

      client.get(route)
    end

    def self.get_offender_registrations(nomis_offender_id)
      safe_offender_no = URI.encode_www_form_component(nomis_offender_id)
      route = "/offenders/nomsNumber/#{safe_offender_no}/registrations"

      client.get(route)
    end

    def self.get_offender_mappa_details(crn)
      route = "/offenders/crn/#{crn}/risk/mappa"
      client.get(route)
    end

    def self.get_all_offender_managers(nomis_offender_id)
      safe_offender_no = URI.encode_www_form_component(nomis_offender_id)
      route = "/offenders/nomsNumber/#{safe_offender_no}/allOffenderManagers"

      client.get(route)
    end

    def self.get_latest_resourcing(nomis_offender_id)
      safe_offender_no = URI.encode_www_form_component(nomis_offender_id)
      route = "/offenders/nomsNumber/#{safe_offender_no}/risk/resourcing/latest"

      client.get(route)
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

      client.put(route, body)

      # So long as the API call didn't error, return true
      # The API response body isn't useful to us
      true
    end

    def self.unset_pom(offender_no)
      safe_offender_no = URI.encode_www_form_component(offender_no)
      route = "/offenders/nomsNumber/#{safe_offender_no}/prisonOffenderManager"

      client.delete(route)

      # So long as the API call didn't error, return true
      # The API response body isn't useful to us
      true
    end
  end
end
