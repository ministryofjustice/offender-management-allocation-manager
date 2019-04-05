# frozen_string_literal: true

module Nomis
  module Models
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
      include MemoryModel

      attribute :offender_no, :string
      attribute :create_date_time, :date
      attribute :from_agency, :string
      attribute :from_agency_description, :string
      attribute :to_agency, :string
      attribute :to_agency_description, :string
      attribute :from_city, :string
      attribute :to_city, :string
      attribute :movement_type, :string
      attribute :movement_type_description, :string
      attribute :direction_code, :string
      attribute :movement_time
      attribute :movement_reason
      attribute :comment_text
    end
  end
end
