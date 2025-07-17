# frozen_string_literal: true

module HmppsApi
  class StaffDetails
    attr_reader :staff_id,
                :first_name,
                :last_name,
                :status,
                :email_address

    def initialize(payload)
      @staff_id = payload['staffId']
      @first_name = payload['firstName']
      @last_name = payload['lastName']
      @status = payload['status']
      @email_address = payload['primaryEmail']
    end
  end
end
