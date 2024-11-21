# frozen_string_literal: true

class PrisonOffenderManagerService
  class << self
    def fetch_pom_name(staff_id, ordered: true)
      staff = HmppsApi::PrisonApi::PrisonOffenderManagerApi.staff_detail(staff_id)

      if ordered
        [staff.first_name, staff.last_name].compact_blank.join(' ').titleize
      else
        [staff.last_name, staff.first_name].compact_blank.join(', ')
      end
    end

    def fetch_pom_email(staff_id)
      HmppsApi::PrisonApi::PrisonOffenderManagerApi.fetch_email_addresses(staff_id).first
    end
  end
end
