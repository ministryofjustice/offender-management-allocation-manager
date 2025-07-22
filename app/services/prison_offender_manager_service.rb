# frozen_string_literal: true

class PrisonOffenderManagerService
  class << self
    def fetch_pom_name(staff_id, ordered: true)
      staff = HmppsApi::NomisUserRolesApi.staff_details(staff_id)

      if ordered
        [staff.first_name, staff.last_name].compact_blank.join(' ').titleize
      else
        [staff.last_name, staff.first_name].compact_blank.join(', ')
      end
    end

    def fetch_pom_email(staff_id)
      HmppsApi::NomisUserRolesApi.email_address(staff_id)
    end
  end
end
