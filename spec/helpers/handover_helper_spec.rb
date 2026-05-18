RSpec.describe HandoverHelper, type: :helper do
  describe '#handover_progress_task_hint_id' do
    it 'derives hint id from the task field' do
      expect(helper.handover_progress_task_hint_id(:reviewed_oasys)).to eq('reviewed-oasys-hint')
      expect(helper.handover_progress_task_hint_id(:attended_handover_meeting)).to eq('attended-handover-meeting-hint')
    end
  end

  describe '#handover_progress_task_label' do
    it 'returns task label from locale copy' do
      expect(helper.handover_progress_task_label(:reviewed_oasys)).to eq('Review the last OASys assessment')
    end
  end

  describe '#handover_progress_task_hint' do
    it 'returns plain task hint from locale copy' do
      expect(helper.handover_progress_task_hint(:contacted_com)).to eq(
        "Highlight any of the prisoner's pre-release or pre-parole needs and any public protection concerns you have identified."
      )
    end

    it 'returns sent handover report hint with EQuiP link' do
      hint = helper.handover_progress_task_hint(:sent_handover_report)

      aggregate_failures do
        expect(hint).to include('You can find a template for this in the')
        expect(hint).to include('handover guidance on EQuiP')
        expect(hint).to include('https://equip-portal.equip.service.justice.gov.uk/')
        expect(hint).to include('rel="noopener"')
      end
    end
  end
end
