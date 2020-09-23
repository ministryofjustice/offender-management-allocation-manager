# frozen_string_literal: true

module HmppsApi
  module Prison
    class User
      extend PrisonApiBase

      def self.user_details(username)
        route = "/users/#{username}"
        response = e2_client.get(route)

        user = api_deserialiser.deserialise(Nomis::UserDetails, response)
        user.email_address =
          HmppsApi::Prison::PrisonOffenderManager.fetch_email_addresses(user.staff_id)
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
