module Nomis
  class ReleaseDetails
    include MemoryModel

    attribute :approved_release_date, :string
    attribute :auto_release_date, :string
    attribute :booking_id, :string
    attribute :comments, :string
    attribute :dto_approved_date, :string
    attribute :dto_mid_term_date, :string
    attribute :event_id, :integer
    attribute :event_status, :string
    attribute :movement_reason_type, :string
    attribute :movement_reason_code, :string
    attribute :movement_reason_description, :string
    attribute :release_date, :string
    attribute :verified, :boolean
  end
end
