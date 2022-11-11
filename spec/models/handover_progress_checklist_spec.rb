RSpec.describe HandoverProgressChecklist do
  subject(:checklist) { described_class.new }

  describe '#progress_data' do
    describe 'when 3 tasks' do
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
  end
end
