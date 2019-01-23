module Allocation
  class FakeAllocationRecord
    def self.generate(staff_id)
      tier_counts = generate_tier_counts_from(staff_id)
      new(staff_id, tier_counts)
    end

    def self.generate_tier_counts_from(staff_id)
      last_digit = staff_id.split('').last.to_i

      {
        a: last_digit % 1,
        b: last_digit % 2,
        c: last_digit % 3,
        d: last_digit % 4
      }
    end

    private_class_method :generate_tier_counts_from

    ACTIVE = 'active'

    attr_reader :staff_id, :tier_a, :tier_b, :tier_c, :tier_d

    def initialize(staff_id, tier_counts)
      @staff_id = staff_id
      @tier_a = tier_counts[:a]
      @tier_b = tier_counts[:b]
      @tier_c = tier_counts[:c]
      @tier_d = tier_counts[:d]
    end

    def total_cases
      tier_a + tier_b + tier_c + tier_d
    end

    def status
      ACTIVE
    end
  end
end
