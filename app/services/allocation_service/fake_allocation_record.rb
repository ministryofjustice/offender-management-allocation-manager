module AllocationService
  class FakeAllocationRecord
    def self.generate(staff_id)
      last_digit = staff_id.split('').last.to_i
      tier_counts = generate_tier_counts_from(last_digit)
      working_pattern = generate_working_pattern_from(last_digit)

      new(staff_id, working_pattern, tier_counts)
    end

    def self.generate_tier_counts_from(last_digit)
      {
        a: last_digit % 1,
        b: last_digit % 2,
        c: last_digit % 3,
        d: last_digit % 4
      }
    end

    def self.generate_working_pattern_from(last_digit)
      if last_digit.even?
        'Full time'
      else
        'Part time'
      end
    end

    private_class_method :generate_tier_counts_from, :generate_working_pattern_from

    attr_reader :staff_id, :tier_a, :tier_b, :tier_c, :tier_d, :working_pattern

    def initialize(staff_id, working_pattern, tier_counts)
      @staff_id = staff_id
      @tier_a = tier_counts[:a]
      @tier_b = tier_counts[:b]
      @tier_c = tier_counts[:c]
      @tier_d = tier_counts[:d]
      @working_pattern = working_pattern
    end

    def total_cases
      tier_a + tier_b + tier_c + tier_d
    end

    def status
      'Active'
    end
  end
end
