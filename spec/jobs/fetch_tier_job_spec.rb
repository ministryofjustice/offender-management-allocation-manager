# frozen_string_literal: true

require "rails_helper"

RSpec.describe FetchTierJob, type: :job do
  subject(:job) { described_class.new }

  let(:crn) { 'X362207' }
  let(:service_result) { TierUpdateService::Result.new(status: :unchanged, version: 3) }

  before do
    allow(TierUpdateService).to receive(:call).and_return(service_result)
  end

  describe '#perform' do
    it 'passes job context tags to the service' do
      job.perform(crn, trigger_method: :manual)

      expect(TierUpdateService).to have_received(:call).with(
        crn:, audit_tags: %w[job manual]
      )
    end

    context 'when tier API fetch fails' do
      let(:service_result) { TierUpdateService::Result.new(status: :tier_api_failed, version: 3) }

      it 'logs a warning and returns early' do
        allow(job.logger).to receive(:warn)

        job.perform(crn)

        expect(job.logger).to have_received(:warn).with(/event=tier_api_failed/)
      end
    end

    context 'when tier is unchanged' do
      let(:service_result) do
        TierUpdateService::Result.new(status: :unchanged, old_tier: 'A', new_tier: 'A', version: 3)
      end

      it 'does not emit success or error logs' do
        allow(job.logger).to receive(:info)
        allow(job.logger).to receive(:error)

        job.perform(crn)

        expect(job.logger).not_to have_received(:info).with(/event=tier_updated/)
        expect(job.logger).not_to have_received(:error).with(/event=tier_update_failed/)
      end
    end

    context 'when tier changes successfully' do
      let(:service_result) do
        TierUpdateService::Result.new(status: :updated, old_tier: 'A', new_tier: 'B', version: 3)
      end

      it 'logs a success message' do
        allow(job.logger).to receive(:info)

        job.perform(crn)

        expect(job.logger).to have_received(:info).with(/event=tier_updated,old_tier=A,new_tier=B/)
      end
    end

    context 'when tier update fails validation' do
      let(:service_result) do
        TierUpdateService::Result.new(
          status: :update_failed,
          old_tier: 'A',
          new_tier: 'Z',
          version: 3,
          errors: 'Invalid tier'
        )
      end

      it 'logs an error' do
        allow(job.logger).to receive(:error)

        job.perform(crn)

        expect(job.logger).to have_received(:error).with(/event=tier_update_failed/)
      end
    end
  end
end
