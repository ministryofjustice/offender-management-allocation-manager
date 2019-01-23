# Note this is currently deserializing keyworker
module Nomis
  module Elite2
    class PrisonerOffenderManager
      include MemoryModel

      attribute :staff_id, :string
      attribute :first_name, :string
      attribute :last_name, :string
      attribute :number_allocated, :string

      attr_accessor :tier_a, :tier_b, :tier_c, :tier_d, :total_cases

      def full_name
        "#{last_name}, #{first_name}".titleize
      end
    end
  end
end
