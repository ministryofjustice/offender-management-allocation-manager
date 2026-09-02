# frozen_string_literal: true

RSpec.describe DomainEvents::Handlers::PrisonerMergeHandler do
  subject(:handler) { described_class.new }

  let(:old_id) { 'A3646EA' }
  let(:new_id) { 'A3645EA' }
  let(:event_type) { 'prison-offender-events.prisoner.merged' }
  let(:event) do
    DomainEvents::Event.new(
      event_type:,
      version: 1,
      description: 'A prisoner has been merged',
      additional_information: {
        'nomsNumber' => new_id,
        'removedNomsNumber' => old_id,
      },
      external_event: true,
    )
  end

  before do
    allow(Shoryuken::Logging.logger).to receive(:info)
    allow(ProcessPrisonerMergeJob).to receive(:perform_later)
  end

  describe 'domain event registration' do
    it 'routes prisoner merge events to this handler' do
      expect(Rails.configuration.domain_event_handlers).to include(
        event_type => 'DomainEvents::Handlers::PrisonerMergeHandler',
      )
    end
  end

  context 'when old offender is tracked locally' do
    before do
      allow(PrisonerMergeService).to receive(:locally_tracked?).with(old_id).and_return(true)
    end

    it 'enqueues ProcessPrisonerMergeJob with IDs and event type', :queueing do
      allow(ProcessPrisonerMergeJob).to receive(:perform_later).and_call_original

      expect { handler.handle(event) }
        .to have_enqueued_job(ProcessPrisonerMergeJob)
        .with(old_id, new_id, event_type:)
    end

    it 'logs start and success' do
      handler.handle(event)

      expect(Shoryuken::Logging.logger).to have_received(:info)
        .with(/event=domain_event_handle_start.*old_offender_id=#{old_id}.*new_offender_id=#{new_id}/)
      expect(Shoryuken::Logging.logger).to have_received(:info)
        .with(/event=domain_event_handle_success.*old_offender_id=#{old_id}.*new_offender_id=#{new_id}/)
    end

    it 'does not emit noop log' do
      handler.handle(event)

      expect(Shoryuken::Logging.logger).not_to have_received(:info).with(/event=domain_event_handle_noop/)
    end
  end

  context 'when old offender is not tracked locally' do
    before do
      allow(PrisonerMergeService).to receive(:locally_tracked?).with(old_id).and_return(false)
    end

    it 'does not enqueue ProcessPrisonerMergeJob' do
      handler.handle(event)

      expect(ProcessPrisonerMergeJob).not_to have_received(:perform_later)
    end

    it 'emits noop and success logs' do
      handler.handle(event)

      expect(Shoryuken::Logging.logger).to have_received(:info)
        .with(/event=domain_event_handle_noop.*old_offender_id=#{old_id}.*new_offender_id=#{new_id}/)
      expect(Shoryuken::Logging.logger).to have_received(:info)
        .with(/event=domain_event_handle_success.*old_offender_id=#{old_id}.*new_offender_id=#{new_id}/)
    end
  end
end
