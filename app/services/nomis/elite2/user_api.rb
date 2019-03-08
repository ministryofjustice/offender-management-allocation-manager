module Nomis
  module Elite2
    class UserApi
      extend Elite2Api

      def self.fetch_email_addresses(nomis_staff_id)
        route = "/elite2api/api/staff/#{nomis_staff_id}/emails"
        emails = e2_client.get(route)
        emails
      end
    end
  end
end
