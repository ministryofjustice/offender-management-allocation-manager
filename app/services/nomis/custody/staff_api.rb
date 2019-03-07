module Nomis
  module Custody
    class StaffApi
      extend CustodyApi

      def self.list_caseloads(username)
        route = "/custodyapi/api/nomis-staff-users/#{username}"

        response = custody_client.get(route)
        response['nomisCaseloads'].keys
      end
    end
  end
end
