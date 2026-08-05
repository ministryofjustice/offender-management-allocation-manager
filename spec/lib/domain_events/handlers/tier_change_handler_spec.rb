RSpec.describe DomainEvents::Handlers::TierChangeHandler do
  subject!(:handler) { described_class.new }

  let(:crn) { 'X408769' }
  let(:calculation_id) { 'a5e7d3c1-9b4f-4e2a-8c6d-1f3b5a7e9d02' }
  let(:event) do
    DomainEvents::Event.new(
      event_type: 'tier.calculation.changed',
      version: event_version,
      description: 'Tier calculation changed',
      detail_url: "https://hmpps-tier.example.org/crn/#{crn}/tier/#{calculation_id}",
      additional_information: { 'calculationId' => calculation_id },
      crn_number: crn,
      external_event: true
    )
  end
  let(:event_version) { 3 }
  let(:service_result) do
    TierUpdateService::Result.new(status: :updated, old_tier: 'A', new_tier: 'D', version: 3)
  end

  before do
    allow(Shoryuken::Logging.logger).to receive(:info).and_return(nil)
    allow(Shoryuken::Logging.logger).to receive(:error).and_return(nil)
    allow(Shoryuken::Logging.logger).to receive(:warn).and_return(nil)
    allow(TierUpdateService).to receive(:call).and_return(service_result)
  end

  context 'when handling tier change event' do
    before { handler.handle(event) }

    it 'delegates to the shared tier service' do
      expect(TierUpdateService).to have_received(:call).with(
        crn:, audit_tags: %w[handler]
      )
    end

    it 'emits a start log message with event version' do
      expect(Shoryuken::Logging.logger).to have_received(:info).with(/event=domain_event_handle_start.*version=3.*crn=#{crn}/)
    end

    context 'when service reports unchanged' do
      let(:service_result) do
        TierUpdateService::Result.new(status: :unchanged, old_tier: 'D', new_tier: 'D', version: 3)
      end

      it 'does not emit success or failure logs' do
        expect(Shoryuken::Logging.logger).not_to have_received(:info).with(/event=domain_event_handle_success/)
        expect(Shoryuken::Logging.logger).not_to have_received(:error).with(/event=domain_event_handle_failure/)
      end
    end

    context 'when service updates the tier' do
      it 'emits success log with event version' do
        expect(Shoryuken::Logging.logger).to have_received(:info).with(
          /event=domain_event_handle_success.*version=3,crn=#{crn},old_tier=A,new_tier=D/
        )
      end
    end

    context 'when service reports an update failure' do
      let(:service_result) do
        TierUpdateService::Result.new(
          status: :update_failed,
          old_tier: 'A',
          new_tier: 'Z',
          version: 3,
          errors: 'Tier is not included in the list'
        )
      end

      it 'emits failure log' do
        expect(Shoryuken::Logging.logger).to have_received(:error).with(
          /event=domain_event_handle_failure.*version=3,crn=#{crn},old_tier=A,new_tier=Z/
        )
      end
    end

    context 'when tier API fetch fails' do
      let(:service_result) do
        TierUpdateService::Result.new(status: :tier_api_failed, version: 3)
      end

      it 'emits a warning log' do
        expect(Shoryuken::Logging.logger).to have_received(:warn).with(
          /event=domain_event_handle_tier_api_failed.*version=3,crn=#{crn}/
        )
      end
    end
  end
end
