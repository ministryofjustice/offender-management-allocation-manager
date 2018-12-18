module Nomis
  class StaffDetails
    include MemoryModel

    attribute :active_nomis_caseload, :string
    attribute :username, :string
    attribute :staff_id, :integer
    attribute :first_name, :string
    attribute :last_name, :string
    attribute :status
    attribute :nomis_caseloads, :string
  end
end
