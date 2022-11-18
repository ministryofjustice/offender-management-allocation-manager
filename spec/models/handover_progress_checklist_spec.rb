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
          reviewed_oasys: true, # ignored
          contacted_com: false,
          attended_handover_meeting: true,
        }
      end

      it 'returns completed and total tasks (ignoring reviewed_oasys)' do
        expect(checklist.progress_data).to eq('complete' => 1, 'total' => 2)
      end
    end
  end

  describe '#task_completion_data' do
    describe 'when NPS case' do
      let(:expected_data) do
        { 'reviewed_oasys' => false, 'contacted_com' => false, 'attended_handover_meeting' => true }
      end

      before do
        checklist.attributes = expected_data
      end

      it 'returns completion data for NPS fields' do
        expect(checklist.task_completion_data).to eq(expected_data)
      end
    end

    describe 'when CRC case' do
      let(:expected_data) { { 'contacted_com' => false, 'attended_handover_meeting' => true } }

      before do
        allow(checklist.offender).to receive(:case_allocation).and_return('CRC')
        checklist.attributes = expected_data.merge(reviewed_oasys: true) # extra field should be ignored
      end

      it 'returns completion data for NPS fields' do
        expect(checklist.task_completion_data).to eq(expected_data)
      end
    end
  end
end
