RSpec.describe AllocatedOffender do
  describe ':all' do
    it 'enumerates all offenders that have a primary POM allocated' do
      allocations1 = [instance_double(described_class, :offender1a), instance_double(described_class, :offender1b)]
      allocations2 = [instance_double(described_class, :offender2)]
      allow(Prison).to receive(:all).and_return(
        [
          instance_double(Prison, :prison1, primary_allocated_offenders: allocations1),
          instance_double(Prison, :prison2, primary_allocated_offenders: allocations2),
        ]
      )

      expect(described_class.all).to match_array(allocations1 + allocations2)
    end
  end
end
