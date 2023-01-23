RSpec.describe Handovers::HandoverListHelper do
  let(:offender) { instance_double AllocatedOffender, :offender, model: double(handover_date: nil) }

  describe '#com_allocation_overdue_days' do
    def result
      helper.com_allocation_overdue_days(offender, relative_to_date: Date.new(2022, 1, 1))
    end

    describe 'when handover date is not set' do
      it 'raises error' do
        expect { result }.to raise_error(/handover date not set/i)
      end
    end

    describe 'when handover date is the current date' do
      it 'returns 0' do
        allow(offender.model).to receive_messages(handover_date: Date.new(2022, 1, 1))
        expect(result).to be 0
      end
    end

    describe 'when COM responsible date is in the past' do
      it 'returns the days overdue' do
        allow(offender.model).to receive_messages(handover_date: Date.new(2021, 12, 30))
        expect(result).to be 2
      end
    end

    describe 'when COM responsible date is in the future' do
      it 'raises error' do
        allow(offender.model).to receive_messages(handover_date: Date.new(2022, 1, 2))
        expect { result }.to raise_error(/handover date.+in the future/i)
      end
    end
  end
end
