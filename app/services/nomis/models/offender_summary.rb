# frozen_string_literal: true

module Nomis
  module Models
    class OffenderSummary < OffenderBase
      include MemoryModel

      attribute :agency_id, :string
      attribute :aliases, :string
      attribute :booking_id, :integer

      # custom attributes
      attribute :allocation_date, :date
    end
  end
end
