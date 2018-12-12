module Nomis
  class OffenderDetails
    include MemoryModel

    attribute :noms_id, :string
    attribute :offender_id, :string
    attribute :first_name, :string
    attribute :surname, :string
    attribute :date_of_birth, :date
    attribute :active_booking, :string
    attribute :middle_names, :string
  end
end
