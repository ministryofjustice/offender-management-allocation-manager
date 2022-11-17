RSpec.describe HandoverProgressChecklist do
  subject(:checklist) { described_class.new offender: FactoryBot.build(:offender) }

  before do
    allow(checklist.offender).to receive(:case_allocation).and_return('NPS')
  end

  describe '#progress_data' do
    describe 'when NPS case' do
      before do
        checklist.attributes = {
          reviewed_oasys: false,
          contacted_com: false,
          attended_handover_meeting: true,
        }
      end

      it 'returns completed and total tasks' do
        expect(checklist.progress_data).to eq('complete' => 1, 'total' => 3)
      end
    end

    describe 'when CRC case' do
      before do
        allow(checklist.offender).to receive(:case_allocation).and_return('CRC')
        checklist.attributes = {
          reviewed_oasys: true,
          contacted_com: false,
          attended_handover_meeting: true,
        }
      end

      it 'returns completed and total tasks (ignoring reviewed_oasys)' do
        expect(checklist.progress_data).to eq('complete' => 1, 'total' => 2)
      end
    end
  end
end
