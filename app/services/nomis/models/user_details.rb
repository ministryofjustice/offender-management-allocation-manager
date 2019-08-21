# frozen_string_literal: true

module Nomis
  module Models
    class UserDetails
      include MemoryModel

      attribute :account_status, :string
      attribute :active, :boolean
      attribute :active_case_load_id
      attribute :expiry_date
      attribute :expired_flag
      attribute :first_name, :string
      attribute :last_name, :string
      attribute :lock_date
      attribute :locked_flag
      attribute :staff_id, :integer
      attribute :status, :string
      attribute :thumbnail_id, :string
      attribute :username, :string

      # custom attribute - Elite2 requires a separate API call to
      # fetch a user's caseload
      attribute :nomis_caseloads
    end
  end
end