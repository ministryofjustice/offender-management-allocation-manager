module HmppsApi
  class NomisUserRolesApi
    DEFAULT_USER_SEARCH_FILTER = {
      userType: 'GENERAL', status: 'ACTIVE', size: 20
    }.freeze

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

    # See: https://nomis-user-roles-api-dev.prison.service.justice.gov.uk/swagger-ui/index.html#/user-resource/getUsers
    def self.get_users(caseload:, filter:)
      client.get(
        '/users', queryparams: { caseload:, nameFilter: filter }.merge(DEFAULT_USER_SEARCH_FILTER)
      )
    end

    # See: https://nomis-user-roles-api-dev.prison.service.justice.gov.uk/swagger-ui/index.html#/staff-member-resource/setJobClassification
    def self.set_staff_role(agency_id, staff_id, **config)
      client.put(
        "/agency/#{agency_id}/staff-members/#{staff_id}/staff-role/POM",
        {
          fromDate: config.fetch(:fromDate, Time.zone.today),
          position: config.fetch(:position),
          scheduleType: config.fetch(:schedule_type),
          hoursPerWeek: config.fetch(:hours_per_week),
        }
      )
    end

    def self.expire_staff_role(pom)
      client.put(
        "/agency/#{pom.agency_id}/staff-members/#{pom.staff_id}/staff-role/POM",
        {
          toDate: Time.zone.yesterday,
          fromDate: pom.from_date,
          position: pom.position,
          scheduleType: pom.schedule_type,
          hoursPerWeek: pom.hours_per_week,
        }
      )
    end

    def self.email_address(staff_id)
      staff_details(staff_id).email_address
    end
  end
end
