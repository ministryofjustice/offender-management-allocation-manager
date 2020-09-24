# frozen_string_literal: true

module HmppsApi
  module PrisonApi
    class UserApi
      extend PrisonApiClient

      def self.user_details(username)
        route = "/users/#{username}"
        response = e2_client.get(route)

        user = api_deserialiser.deserialise(HmppsApi::UserDetails, response)
        user.email_address =
          HmppsApi::PrisonApi::PrisonOffenderManagerApi.fetch_email_addresses(user.staff_id)
        user
      end

      def self.user_caseloads(staff_id)
        route = "/staff/#{staff_id}/caseloads"
        response = e2_client.get(route)

        response
      end
    end
  end
end
