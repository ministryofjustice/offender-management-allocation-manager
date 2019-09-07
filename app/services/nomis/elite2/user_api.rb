# frozen_string_literal: true

module Nomis
  module Elite2
    class UserApi
      extend Elite2Api

      def self.user_details(username)
        route = "/elite2api/api/users/#{username}"
        response = e2_client.get(route)

        api_deserialiser.deserialise(Nomis::UserDetails, response)
      end

      def self.user_caseloads(staff_id)
        route = "/elite2api/api/staff/#{staff_id}/caseloads"
        response = e2_client.get(route)

        response
      end
    end
  end
end
