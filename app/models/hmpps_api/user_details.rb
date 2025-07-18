# frozen_string_literal: true

module HmppsApi
  class UserDetails
    attr_reader :staff_id,
                :first_name,
                :last_name,
                :enabled,
                :email_address,
                :username,
                :active_case_load_id,
                :role_codes

    def initialize(payload)
      @staff_id = payload['staffId']
      @first_name = payload['firstName']
      @last_name = payload['lastName']
      @enabled = payload['enabled']
      @email_address = payload['primaryEmail']
      @username = payload['username']
      @active_case_load_id = payload['activeCaseloadId']
      @role_codes = payload['dpsRoleCodes']
    end

    def full_name_ordered
      "#{first_name} #{last_name}"
    end
  end
end
