module Nomis
  module Models
    class UserDetails
      include MemoryModel

      attribute :account_status, :string
      attribute :active, :boolean
      attribute :active_nomis_caseload, :string
      attribute :first_name, :string
      attribute :last_name, :string
      attribute :nomis_caseloads
      attribute :staff_id, :integer
      attribute :status, :string
      attribute :thumbnail_id, :string
      attribute :username, :string
      attribute :emails
      attribute :active_case_load_id
    end
  end
end
