module HmppsApi
  class NomisUserRolesApi
    def self.client
      host = Rails.configuration.nomis_user_roles_api_host
      HmppsApi::Client.new(host)
    end

    # See: https://nomis-user-roles-api-dev.prison.service.justice.gov.uk/swagger-ui/index.html#/user-resource/getUserDetailsByStaffId
    def self.staff_details(staff_id, cache: true)
      raise ArgumentError, 'NomisUserRolesApi#staff_details(blank)' if staff_id.blank?

      data = client.get("/users/staff/#{staff_id}", cache:)
      HmppsApi::StaffDetails.new(data)
    end

    # See: https://nomis-user-roles-api-dev.prison.service.justice.gov.uk/swagger-ui/index.html#/user-resource/getUserDetails
    def self.user_details(username, cache: true)
      raise ArgumentError, 'NomisUserRolesApi#user_details(blank)' if username.blank?

      data = client.get("/users/#{username}", cache:)
      HmppsApi::UserDetails.new(data)
    end

    def self.email_address(staff_id)
      staff_details(staff_id).email_address
    end
  end
end
