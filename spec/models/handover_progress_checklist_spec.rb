RSpec.describe HandoverProgressChecklist do
  subject(:checklist) { described_class.new offender: FactoryBot.build(:offender) }

  before do
    allow(checklist.offender).to receive_messages(handover_type: 'enhanced')
  end

  describe '.permitted_task_fields' do
    it 'returns enhanced fields when enhanced and feature disabled' do
      expect(described_class.permitted_task_fields(handover_type: 'enhanced', simplified_enhanced_handover: false)).to eq(
        %i[reviewed_oasys contacted_com attended_handover_meeting]
      )
    end

    it 'returns standard fields when standard and feature disabled' do
      expect(described_class.permitted_task_fields(handover_type: 'standard', simplified_enhanced_handover: false)).to eq(
        %i[contacted_com sent_handover_report]
      )
    end

    it 'returns simplified enhanced fields when feature enabled' do
      expect(described_class.permitted_task_fields(handover_type: 'enhanced', simplified_enhanced_handover: true)).to eq(
        %i[reviewed_oasys contacted_com]
      )
    end

    it 'returns standard fields unchanged when feature enabled' do
      expect(described_class.permitted_task_fields(handover_type: 'standard', simplified_enhanced_handover: true)).to eq(
        %i[contacted_com sent_handover_report]
      )
    end
  end

  context 'when simplified_enhanced_handover feature flag is disabled' do
    before do
      stub_feature_flag(:simplified_enhanced_handover, enabled: false)
    end

    describe '#progress_data' do
      it 'returns completed and total enhanced handover tasks' do
        checklist.attributes = {
          reviewed_oasys: false,
          contacted_com: false,
          sent_handover_report: true, # ignored
          attended_handover_meeting: true,
        }

        expect(checklist.progress_data).to eq('complete' => 1, 'total' => 3)
      end

      it 'returns completed and total standard handover tasks' do
        allow(checklist.offender).to receive_messages(handover_type: 'standard')
        checklist.attributes = {
          reviewed_oasys: true, # ignored
          contacted_com: false,
          sent_handover_report: true,
        }

        expect(checklist.progress_data).to eq('complete' => 1, 'total' => 2)
      end
    end

    describe '#task_completion_data' do
      it 'returns enhanced completion data for enhanced handovers' do
        checklist.attributes = {
          reviewed_oasys: false,
          contacted_com: false,
          attended_handover_meeting: true,
          sent_handover_report: true, # ignored
        }

        expect(checklist.task_completion_data).to eq(
          'reviewed_oasys' => false,
          'contacted_com' => false,
          'attended_handover_meeting' => true,
        )
      end

      it 'returns standard completion data for standard handovers' do
        allow(checklist.offender).to receive_messages(handover_type: 'standard')
        checklist.attributes = {
          reviewed_oasys: true, # ignored
          contacted_com: false,
          sent_handover_report: true,
        }

        expect(checklist.task_completion_data).to eq(
          'contacted_com' => false,
          'sent_handover_report' => true,
        )
      end
    end

    describe '#handover_progress_complete?' do
      it 'is false when any enhanced handover task is incomplete' do
        checklist.attributes = { reviewed_oasys: false, contacted_com: true, attended_handover_meeting: true }
        expect(checklist.handover_progress_complete?).to be(false)
      end

      it 'is true when all enhanced handover tasks are complete' do
        checklist.attributes = { reviewed_oasys: true, contacted_com: true, attended_handover_meeting: true }
        expect(checklist.handover_progress_complete?).to be(true)
      end
    end
  end

  context 'when simplified_enhanced_handover feature flag is enabled' do
    before do
      stub_feature_flag(:simplified_enhanced_handover, enabled: true)
    end

    describe '#progress_data' do
      it 'counts only reviewed_oasys and contacted_com for enhanced handovers' do
        checklist.attributes = { reviewed_oasys: false, contacted_com: true, attended_handover_meeting: true }
        expect(checklist.progress_data).to eq('complete' => 1, 'total' => 2)
      end

      it 'still counts standard tasks for standard handovers' do
        allow(checklist.offender).to receive_messages(handover_type: 'standard')
        checklist.attributes = { contacted_com: false, sent_handover_report: true }
        expect(checklist.progress_data).to eq('complete' => 1, 'total' => 2)
      end
    end

    describe '#task_completion_data' do
      it 'returns only reviewed_oasys and contacted_com for enhanced handovers' do
        checklist.attributes = { reviewed_oasys: false, contacted_com: true, attended_handover_meeting: true }
        expect(checklist.task_completion_data).to eq('reviewed_oasys' => false, 'contacted_com' => true)
      end

      it 'returns standard fields for standard handovers' do
        allow(checklist.offender).to receive_messages(handover_type: 'standard')
        checklist.attributes = { contacted_com: false, sent_handover_report: true }
        expect(checklist.task_completion_data).to eq('contacted_com' => false, 'sent_handover_report' => true)
      end
    end

    describe '#handover_progress_complete?' do
      it 'is false when any simplified enhanced task is incomplete' do
        checklist.attributes = { reviewed_oasys: true, contacted_com: false, attended_handover_meeting: true }
        expect(checklist.handover_progress_complete?).to be(false)
      end

      it 'is true when both simplified enhanced tasks are complete' do
        checklist.attributes = { reviewed_oasys: true, contacted_com: true, attended_handover_meeting: false }
        expect(checklist.handover_progress_complete?).to be(true)
      end
    end
  end
end
