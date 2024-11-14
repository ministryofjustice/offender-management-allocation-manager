RSpec.describe Handover::HandoverCase do
  subject(:hcase) { described_class.new(offender, chd) }

  let(:offender) { sneaky_instance_double AllocatedOffender, :offender }
  let(:chd) { sneaky_instance_double CalculatedHandoverDate, :chd, handover_date: nil }

  describe '#==' do
    it 'returns true when attributes are the same' do
      obj1 = described_class.new(offender, chd)
      obj2 = described_class.new(offender, chd)
      expect(obj1 == obj2).to eq true
    end

    it 'returns false when attributes are not the same' do
      aggregate_failures do
        expect(described_class.new(offender, sneaky_instance_double(CalculatedHandoverDate)))
          .not_to eq described_class.new(offender, chd)
        expect(described_class.new(sneaky_instance_double(AllocatedOffender), chd))
          .not_to eq described_class.new(offender, chd)
      end
    end
  end
end
