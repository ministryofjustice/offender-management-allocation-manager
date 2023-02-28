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
        expect(described_class.new(offender, sneaky_instance_double(CalculatedHandoverDate)) ==
                 described_class.new(offender, chd)).to eq false
        expect(described_class.new(sneaky_instance_double(AllocatedOffender), chd) ==
          described_class.new(offender, chd)).to eq false
      end
    end
  end

  describe '#com_allocation_days_overdue' do
    let(:result) { hcase.com_allocation_days_overdue(relative_to_date: Date.new(2022, 1, 1)) }

    describe 'when handover date is not set' do
      it 'raises error' do
        expect { result }.to raise_error(/handover date not set/i)
      end
    end

    describe 'when handover date is the current date' do
      it 'returns 0' do
        allow(chd).to receive_messages(handover_date: Date.new(2022, 1, 1))
        expect(result).to eq 0
      end
    end

    describe 'when COM responsible date is in the past' do
      it 'returns the days overdue' do
        allow(chd).to receive_messages(handover_date: Date.new(2021, 12, 30))
        expect(result).to eq 2
      end
    end

    describe 'when COM responsible date is in the future' do
      it 'returns days overdue as negative number' do
        allow(chd).to receive_messages(handover_date: Date.new(2022, 1, 2))
        expect(result).to eq(-1)
      end
    end
  end
end
