# frozen_string_literal: true

module HmppsApi
  class StaffDetails
    attr_reader :staff_id,
                :first_name,
                :last_name,
                :status,
                :email_address,
                :active,
                :username,
                :active_case_load_id,
                :caseloads

    def initialize(payload)
      @staff_id = payload['staffId']
      @first_name = payload['firstName']
      @last_name = payload['lastName']
      @status = payload['status']
      @email_address = payload['primaryEmail']
      @active = payload.dig('generalAccount', 'active')
      @username = payload.dig('generalAccount', 'username')
      @active_case_load_id = payload.dig('generalAccount', 'activeCaseload', 'id')
      @caseloads = (payload.dig('generalAccount', 'caseloads') || []).pluck('id').sort
    end

    def full_name_ordered
      "#{first_name} #{last_name}"
    end
  end
end
