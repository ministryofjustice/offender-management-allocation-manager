module Nomis
  module Elite2
    class UserApi
      extend Elite2Api

      def self.user_details(username)
        route = "/elite2api/api/users/#{username}"
        response = e2_client.get(route)

        api_deserialiser.deserialise(Nomis::Models::UserDetails, response)
      end
    end
  end
end
