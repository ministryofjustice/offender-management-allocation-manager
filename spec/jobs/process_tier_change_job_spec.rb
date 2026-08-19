# frozen_string_literal: true

RSpec.describe ProcessTierChangeJob, type: :job do
  let(:crn) { 'X408769' }
  let(:event_type) { 'tier.calculation.changed' }

  it 'is enqueued on the deferred queue' do
    expect(described_class.new.queue_name).to eq('deferred')
  end

  context 'when the tier is updated successfully' do
    let(:service_result) do
      TierUpdateService::Result.new(status: :updated, old_tier: 'A', new_tier: 'D', version: 3)
    end

    before { allow(TierUpdateService).to receive(:call).and_return(service_result) }

    it 'calls TierUpdateService with the correct CRN and audit tags' do
      described_class.perform_now(crn, event_type:)

      expect(TierUpdateService).to have_received(:call).with(crn:, audit_tags: ['handler'])
    end

    it 'logs a success message' do
      allow(Rails.logger).to receive(:info)
      described_class.perform_now(crn, event_type:)
      expect(Rails.logger).to have_received(:info).with(/event=process_tier_change_job_success.*old_tier=A,new_tier=D/)
    end
  end

  context 'when tier update fails during persistence' do
    let(:service_result) do
      TierUpdateService::Result.new(
        status: :update_failed,
        old_tier: 'A',
        new_tier: 'D',
        version: 3,
        errors: 'Could not save case information'
      )
    end

    before { allow(TierUpdateService).to receive(:call).and_return(service_result) }

    it 'logs a failure message' do
      allow(Rails.logger).to receive(:error)
      described_class.perform_now(crn, event_type:)
      expect(Rails.logger).to have_received(:error).with(/event=process_tier_change_job_failure.*old_tier=A,new_tier=D/)
    end
  end

  context 'when the tier API fetch fails' do
    let(:service_result) do
      TierUpdateService::Result.new(status: :tier_api_failed, version: 3)
    end

    before { allow(TierUpdateService).to receive(:call).and_return(service_result) }

    it 'logs a warning message' do
      allow(Rails.logger).to receive(:warn)
      described_class.perform_now(crn, event_type:)
      expect(Rails.logger).to have_received(:warn).with(/event=process_tier_change_job_tier_api_failed.*crn=#{crn}/)
    end
  end

  context 'when tier returned by API is unsupported' do
    let(:service_result) do
      TierUpdateService::Result.new(
        status: :invalid_tier,
        old_tier: 'A',
        new_tier: 'Z',
        version: 2,
        errors: "Unsupported tier 'Z'. Accepted tiers: A,B,C,D"
      )
    end

    before { allow(TierUpdateService).to receive(:call).and_return(service_result) }

    it 'logs an invalid tier error' do
      allow(Rails.logger).to receive(:error)
      described_class.perform_now(crn, event_type:)
      expect(Rails.logger).to have_received(:error).with(/event=process_tier_change_job_invalid_tier.*old_tier=A,new_tier=Z/)
    end
  end
end
