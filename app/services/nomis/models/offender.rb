# frozen_string_literal: true

module Nomis
  module Models
    class Offender < OffenderBase
      include MemoryModel

      attribute :convicted_status, :string
      attribute :date_of_birth, :date
      attribute :first_name, :string
      attribute :gender, :string
      attribute :imprisonment_status, :string
      attribute :last_name, :string
      attribute :latest_booking_id, :integer
      attribute :main_offence, :string
      attribute :nationalities, :string
      attribute :noms_id, :string
      attribute :offender_no, :string
      attribute :reception_date, :date

      # custom attributes
      attribute :allocated_pom_name, :string
      attribute :case_allocation, :string
      attribute :omicable, :boolean
      attribute :tier, :string
      attribute :sentence
    end
  end
end
