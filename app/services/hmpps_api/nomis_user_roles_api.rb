module HmppsApi
  class NomisUserRolesApi
    def self.client
      host = Rails.configuration.nomis_user_roles_api_host
      HmppsApi::Client.new(host)
    end

    # See: https://nomis-user-roles-api-dev.prison.service.justice.gov.uk/swagger-ui/index.html#/user-resource/getUserDetailsByStaffId
    def self.staff_details(staff_id)
      data = client.get("/users/staff/#{staff_id}")
      HmppsApi::StaffDetails.new(data)
    end
  end
end
