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

  before do
    allow(Shoryuken::Logging.logger).to receive(:info).and_return(nil)
    # Prevent the job running inline during handler-focused examples
    allow(ProcessTierChangeJob).to receive(:perform_later)
  end

  context 'when handling a tracked tier change event' do
    before do
      allow(CaseInformation).to receive(:exists?).with(crn: crn).and_return(true)
    end

    it 'enqueues a ProcessTierChangeJob on the deferred queue', :queueing do
      allow(ProcessTierChangeJob).to receive(:perform_later).and_call_original

      expect { handler.handle(event) }
        .to have_enqueued_job(ProcessTierChangeJob)
        .with(crn, event_type: 'tier.calculation.changed')
        .on_queue(:deferred)
    end

    it 'checks if the CRN is tracked locally before enqueuing' do
      handler.handle(event)

      expect(CaseInformation).to have_received(:exists?).with(crn: crn)
    end

    it 'emits a start log message with event version and CRN' do
      handler.handle(event)

      expect(Shoryuken::Logging.logger).to have_received(:info)
        .with(/event=domain_event_handle_start.*event_version=3.*crn=#{crn}/)
    end

    it 'emits a success log message after enqueuing' do
      handler.handle(event)

      expect(Shoryuken::Logging.logger).to have_received(:info)
        .with(/event=domain_event_handle_success.*event_version=3.*crn=#{crn}/)
    end
  end

  context 'when CRN is not tracked locally' do
    before do
      allow(CaseInformation).to receive(:exists?).with(crn: crn).and_return(false)
    end

    it 'does not enqueue a job' do
      handler.handle(event)

      expect(ProcessTierChangeJob).not_to have_received(:perform_later)
    end

    it 'still emits a success log' do
      handler.handle(event)

      expect(Shoryuken::Logging.logger).to have_received(:info)
        .with(/event=domain_event_handle_success.*event_version=3.*crn=#{crn}/)
    end
  end
end
