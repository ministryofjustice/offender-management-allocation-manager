# frozen_string_literal: true

module Nomis
  class UserDetails
    include Deserialisable

    attr_accessor :account_status,
                  :active,
                  :active_case_load_id,
                  :expiry_date,
                  :expired_flag,
                  :first_name,
                  :last_name,
                  :lock_date,
                  :locked_flag,
                  :staff_id,
                  :status,
                  :thumbnail_id,
                  :username

    # custom attribute - Elite2 requires a separate API call to
    # fetch a user's caseload
    attr_accessor :nomis_caseloads,
                  :email_address

    def self.from_json(payload)
      UserDetails.new.tap { |obj|
        obj.account_status = payload['accountStatus']
        obj.active = payload['active']
        obj.active_case_load_id = payload['activeCaseLoadId']
        obj.expiry_date = payload['expiryDate']
        obj.expired_flag = payload['expiredFlag']
        obj.first_name = payload['firstName']
        obj.last_name = payload['lastName']
        obj.lock_date = payload['lockDate']
        obj.locked_flag = payload['lockedFlag']
        obj.staff_id = payload['staffId']&.to_i
        obj.status = payload['status']
        obj.thumbnail_id = payload['thumbnailId']
        obj.username = payload['username']
      }
    end

    def full_name_ordered
      "#{first_name} #{last_name}".titleize
    end
  end
end
