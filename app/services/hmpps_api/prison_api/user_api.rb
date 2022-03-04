# frozen_string_literal: true

module HmppsApi
  module PrisonApi
    class UserApi
      extend PrisonApiClient

      def self.user_details(username)
        raise ArgumentError, 'PrisonApiClient#user_details(blank)' if username.blank?

        route = "/users/#{username}"
        response = client.get(route)

        user = api_deserialiser.deserialise(HmppsApi::UserDetails, response)
        user.email_address =
          HmppsApi::PrisonApi::PrisonOffenderManagerApi.fetch_email_addresses(user.staff_id)
        user
      end

      def self.user_caseloads(staff_id)
        route = "/staff/#{staff_id}/caseloads"
        client.get(route)
      end
    end
  end
end
