module Nomis
  module Elite2
    class PrisonOffenderManager
      include MemoryModel

      attribute :staff_id, :string
      attribute :first_name, :string
      attribute :last_name, :string
      attribute :agency_id, :string
      attribute :agency_description, :string
      attribute :from_date, :date
      attribute :position, :string
      attribute :position_description, :string
      attribute :role, :string
      attribute :role_description, :string
      attribute :schedule_type, :string
      attribute :schedule_type_description, :string
      attribute :hours_per_week, :integer
      attribute :thumbnail_id, :string

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

      def add_detail(pom_detail)
        allocations = pom_detail.allocations.where(active: true)
        allocation_counts = get_allocation_counts(allocations)
        self.tier_a = allocation_counts['A']
        self.tier_b = allocation_counts['B']
        self.tier_c = allocation_counts['C']
        self.tier_d = allocation_counts['D']
        self.total_cases = [tier_a, tier_b, tier_c, tier_d].sum
        self.status = pom_detail.status
        self.working_pattern = pom_detail.working_pattern
      end

    private

      def get_allocation_counts(allocations)
        allocation_counts = {}
        allocation_counts.default = 0

        allocations.each do |a|
          allocation_counts[a.allocated_at_tier] += 1
        end

        allocation_counts
      end
    end
  end
end
