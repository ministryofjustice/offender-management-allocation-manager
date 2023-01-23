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
          sent_handover_report: true, # ignored
          attended_handover_meeting: true,
        }
      end

      it 'returns completed and total NPS tasks' do
        expect(checklist.progress_data).to eq('complete' => 1, 'total' => 3)
      end
    end

    describe 'when CRC case' do
      before do
        allow(checklist.offender).to receive(:case_allocation).and_return('CRC')
        checklist.attributes = {
          reviewed_oasys: true, # ignored
          contacted_com: false,
          sent_handover_report: true,
        }
      end

      it 'returns completed and total CRC tasks' do
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
        checklist.attributes = expected_data.merge(sent_handover_report: true) # extra field should be ignored
      end

      it 'returns completion data for NPS fields' do
        expect(checklist.task_completion_data).to eq(expected_data)
      end
    end

    describe 'when CRC case' do
      let(:expected_data) { { 'contacted_com' => false, 'sent_handover_report' => true } }

      before do
        allow(checklist.offender).to receive(:case_allocation).and_return('CRC')
        checklist.attributes = expected_data.merge(reviewed_oasys: true) # extra field should be ignored
      end

      it 'returns completion data for NPS fields' do
        expect(checklist.task_completion_data).to eq(expected_data)
      end
    end
  end

  describe '#handover_progress_complete?' do
    describe 'when NPS case' do
      it 'is false when all tasks are not complete' do
        aggregate_failures do
          checklist.attributes = { reviewed_oasys: false, contacted_com: true, attended_handover_meeting: true }
          expect(checklist.handover_progress_complete?).to eq false

          checklist.attributes = { reviewed_oasys: true, contacted_com: false, attended_handover_meeting: true }
          expect(checklist.handover_progress_complete?).to eq false

          checklist.attributes = { reviewed_oasys: true, contacted_com: true, attended_handover_meeting: false }
          expect(checklist.handover_progress_complete?).to eq false
        end
      end

      it 'is true when all tasks are complete' do
        checklist.attributes = { reviewed_oasys: true, contacted_com: true, attended_handover_meeting: true }
        expect(checklist.handover_progress_complete?).to eq true
      end
    end

    describe 'when CRC case' do
      before do
        allow(checklist.offender).to receive(:case_allocation).and_return('CRC')
      end

      it 'is false when all tasks are not complete' do
        aggregate_failures do
          checklist.attributes = { contacted_com: false, sent_handover_report: true }
          expect(checklist.handover_progress_complete?).to eq false

          checklist.attributes = { contacted_com: true, sent_handover_report: false }
          expect(checklist.handover_progress_complete?).to eq false
        end
      end

      it 'is true when all tasks are complete' do
        checklist.attributes = { contacted_com: true, sent_handover_report: true }
        expect(checklist.handover_progress_complete?).to eq true
      end
    end
  end
end
