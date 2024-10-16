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

  describe '#formatted_pom_name' do
    subject { described_class.new(staff_id, allocation, offender) }

    let(:staff_id) { 123 }
    let(:allocation) { instance_double(AllocationHistory, primary_pom_name:) }
    let(:offender) { instance_double(Offender) }

    let(:primary_pom_name) { 'DOE, JOHN' }

    it 'formats the POM name' do
      expect(subject.formatted_pom_name).to eq('John Doe')
    end

    context 'when there is no comma separator' do
      let(:primary_pom_name) { 'JOHN' }

      it 'formats the POM name' do
        expect(subject.formatted_pom_name).to eq('John')
      end
    end
  end
end
