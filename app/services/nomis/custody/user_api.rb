module Nomis
  module Custody
    class StaffApi
      extend CustodyApi

      def self.list_caseloads(username)
        route = "/custodyapi/api/nomis-staff-users/#{username}"

        response = custody_client.get(route)
        response['nomisCaseloads'].keys
      end

      def self.user_details(username)
        route = "/custodyapi/api/nomis-staff-users/#{username}"
        response = custody_client.get(route)

        api_deserialiser.deserialise(Nomis::Models::UserDetails, response)
      end
    end
  end
end
