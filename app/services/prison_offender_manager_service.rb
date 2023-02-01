# frozen_string_literal: true

class PrisonOffenderManagerService
  class << self
    def fetch_pom_name(staff_id)
      staff = HmppsApi::PrisonApi::PrisonOffenderManagerApi.staff_detail(staff_id)
      "#{staff.last_name}, #{staff.first_name}"
    end

    def fetch_pom_email(staff_id)
      HmppsApi::PrisonApi::PrisonOffenderManagerApi.fetch_email_addresses(staff_id).first
    end
  end
end
