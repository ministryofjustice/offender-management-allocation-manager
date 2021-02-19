# frozen_string_literal: true

module HmppsApi
  class Movement
    include Deserialisable

    attr_reader :movement_type, :movement_date, :from_agency, :to_agency, :offender_no

    def initialize(fields = {})
      # Allow this object to be reconstituted from a hash, we can't use
      # from_json as the one passed in will already be using the snake case
      # names whereas from_json is expecting the elite2 camelcase names.
      fields.each { |k, v| instance_variable_set("@#{k}", v) }
    end

    def from_prison?
      PrisonService::PRISONS.include?(@from_agency)
    end

    def to_prison?
      PrisonService::PRISONS.include?(@to_agency)
    end

    def temporary?
      @movement_type == HmppsApi::MovementType::TEMPORARY
    end

    def out?
      @direction_code == MovementDirection::OUT
    end

    def in?
      @direction_code == MovementDirection::IN
    end

    def load_from_json(payload)
      @offender_no = payload.fetch('offenderNo')
      @from_agency = payload['fromAgency']
      @to_agency = payload['toAgency']
      @movement_type = payload.fetch('movementType')
      @direction_code = payload.fetch('directionCode')
      @movement_time = payload['movementTime']
      @movement_date = deserialise_date(payload, 'movementDate')
    end

    def self.from_json(payload)
      Movement.new.tap { |obj|
        obj.load_from_json(payload)
      }
    end
  end
end
