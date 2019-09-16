# frozen_string_literal: true

module Nomis
  class MovementType
    RELEASE = 'REL'
    TRANSFER = 'TRN'
    ADMISSION = 'ADM'
  end

  class MovementDirection
    IN = 'IN'
    OUT = 'OUT'
  end

  class Movement
    include Deserialisable

    attr_accessor :offender_no, :create_date_time,
                  :from_agency, :from_agency_description,
                  :to_agency, :to_agency_description,
                  :from_city, :to_city,
                  :movement_type, :movement_type_description,
                  :direction_code, :movement_time,
                  :movement_reason, :comment_text

    def initialize(fields = nil)
      # Allow this object to be reconstituted from a hash, we can't use
      # from_json as the one passed in will already be using the snake case
      # names whereas from_json is expecting the elite2 camelcase names.
      fields.each { |k, v| instance_variable_set("@#{k}", v) } if fields.present?
    end

    def from_prison?
      PrisonService::PRISONS.include?(from_agency)
    end

    def to_prison?
      PrisonService::PRISONS.include?(to_agency)
    end

    def self.from_json(payload)
      Movement.new.tap { |obj|
        obj.offender_no = payload['offenderNo']
        obj.create_date_time = deserialise_date_and_time(payload, 'createDateTime')
        obj.from_agency = payload['fromAgency']
        obj.from_agency_description = payload['fromAgencyDescription']
        obj.to_agency = payload['toAgency']
        obj.to_agency_description = payload['toAgencyDescription']
        obj.from_city = payload['fromCity']
        obj.to_city = payload['toCity']
        obj.movement_type = payload['movementType']
        obj.movement_type_description = payload['movementTypeDescription']
        obj.direction_code = payload['directionCode']
        obj.movement_time = payload['movementTime']
        obj.movement_reason = payload['movementReason']
        obj.comment_text = payload['commentText']
      }
    end
  end
end
