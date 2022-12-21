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

  describe '::with_incomplete_tasks' do
    before do
      # completed rows
      FactoryBot.create :handover_progress_checklist, :nps_complete
      FactoryBot.create :handover_progress_checklist, :crc_complete
    end

    it 'finds incomplete nps rows' do
      incomplete_rows = [
        FactoryBot.create(:handover_progress_checklist, :nps_complete, reviewed_oasys: false),
        FactoryBot.create(:handover_progress_checklist, :nps_complete, contacted_com: false),
        FactoryBot.create(:handover_progress_checklist, :nps_complete, attended_handover_meeting: false),
      ]

      expect(described_class.with_incomplete_tasks).to match_array(incomplete_rows)
    end

    it 'finds incomplete crc rows' do
      incomplete_rows = [
        FactoryBot.create(:handover_progress_checklist, :crc_complete, contacted_com: false),
        FactoryBot.create(:handover_progress_checklist, :crc_complete, sent_handover_report: false),
      ]

      expect(described_class.with_incomplete_tasks).to match_array(incomplete_rows)
    end
  end
end
