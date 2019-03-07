module Nomis
  module Custody
    class UserApi
      extend CustodyApi

      def self.user_details(username)
        route = "/custodyapi/api/nomis-staff-users/#{username}"
        response = custody_client.get(route)

        api_deserialiser.deserialise(Nomis::Models::UserDetails, response)
      end
    end
  end
end
