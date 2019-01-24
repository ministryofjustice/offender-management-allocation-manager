# Note this is currently deserializing a Nomis Keyworker
module Nomis
  module Elite2
    class PrisonOffenderManager
      include MemoryModel

      attribute :staff_id, :string
      attribute :first_name, :string
      attribute :last_name, :string
      attribute :number_allocated, :string

      attr_accessor :tier_a,
        :tier_b,
        :tier_c,
        :tier_d,
        :status,
        :total_cases,
        :working_pattern

      def full_name
        "#{last_name}, #{first_name}".titleize
      end
    end
  end
end
