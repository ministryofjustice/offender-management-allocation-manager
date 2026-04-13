require 'rails_helper'

RSpec.describe HandoverReminderBatchJob, type: :job do
  describe '#perform' do
    it 'runs the handover reminder batch for the given date' do
      for_date = Date.new(2026, 4, 13)
      allow(Handover::HandoverEmailBatchRun).to receive(:send_all)

      described_class.perform_now(for_date)

      expect(Handover::HandoverEmailBatchRun).to have_received(:send_all).with(for_date: for_date)
    end
  end
end
