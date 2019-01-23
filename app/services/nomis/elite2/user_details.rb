module Nomis
  module Elite2
    class UserDetails
      include MemoryModel

      attribute :staff_id, :integer
      attribute :username, :string
      attribute :first_name, :string
      attribute :last_name, :string
      attribute :active_case_load_id, :string
      attribute :locked_flag, :string
      attribute :expired_flag, :string
      attribute :thumbnail_id, :string
    end
  end
end
