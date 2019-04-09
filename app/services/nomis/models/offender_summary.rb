# frozen_string_literal: true

module Nomis
  module Models
    class OffenderSummary < OffenderBase
      include MemoryModel

      attribute :agency_id, :string
      attribute :aliases, :string
      attribute :booking_id, :integer
      attribute :date_of_birth, :string
      attribute :facial_image_id, :string
      attribute :first_name, :string
      attribute :last_name, :string
      attribute :offender_no, :string

      # custom attributes
      attribute :allocated_pom_name, :string
      attribute :allocation_date, :date
      attribute :case_allocation, :string
      attribute :convicted_status, :string
      attribute :imprisonment_status, :string
      attribute :omicable, :boolean
      attribute :tier, :string
      attribute :sentence
    end
  end
end
