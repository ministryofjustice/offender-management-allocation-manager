# Note this is currently deserializing a Nomis Keyworker
module Nomis
  module Elite2
    class PrisonOffenderManager
      include MemoryModel

      attribute :staff_id, :string
      attribute :first_name, :string
      attribute :last_name, :string
      attribute :number_allocated, :string

      attribute :tier_a, :integer
      attribute :tier_b, :integer
      attribute :tier_c, :integer
      attribute :tier_d, :integer
      attribute :total_cases, :integer
      attribute :status, :string
      attribute :working_pattern, :string

      def full_name
        "#{last_name}, #{first_name}".titleize
      end
    end
  end
end
