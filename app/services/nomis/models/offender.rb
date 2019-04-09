# frozen_string_literal: true

module Nomis
  module Models
    class Offender < OffenderBase
      include MemoryModel

      attribute :gender, :string
      attribute :latest_booking_id, :integer
      attribute :main_offence, :string
      attribute :nationalities, :string
      attribute :noms_id, :string
      attribute :reception_date, :date
    end
  end
end
