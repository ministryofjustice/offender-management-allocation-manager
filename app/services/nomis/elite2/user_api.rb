module Nomis
  module Elite2
    class UserApi
      extend Elite2Api

      def self.fetch_email_addresses(nomis_staff_id)
        route = "/elite2api/api/staff/#{nomis_staff_id}/emails"
        data = e2_client.get(route)
        return [] if data.nil?

        data
      end
    end
  end
end
