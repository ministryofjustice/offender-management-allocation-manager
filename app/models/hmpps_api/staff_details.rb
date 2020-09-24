# frozen_string_literal: true

module HmppsApi
  class StaffDetails
    include Deserialisable

    attr_accessor :staff_id,
                  :first_name,
                  :last_name,
                  :status,
                  :thumbnail_id

    def self.from_json(payload)
      StaffDetails.new.tap { |obj|
        obj.staff_id = payload['staffId']
        obj.first_name = payload['firstName']
        obj.last_name = payload['lastName']
        obj.status = payload['status']
        obj.thumbnail_id = payload['thumbnailId']
      }
    end
  end
end
