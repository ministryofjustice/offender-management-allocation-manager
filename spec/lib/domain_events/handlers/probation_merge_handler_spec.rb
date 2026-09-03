RSpec.describe DomainEvents::Handlers::ProbationMergeHandler do
  subject(:handler) { described_class.new }

  let(:old_crn) { 'X12345' }
  let(:new_crn) { 'X54321' }
  let(:event_type) { 'probation-case.merge.completed' }
  let(:event) do
    DomainEvents::Event.new(
      event_type:,
      version: 1,
      description: 'A probation case merge has completed',
      additional_information: {
        'sourceCRN' => old_crn,
        'targetCRN' => new_crn,
      },
      external_event: true,
    )
  end

  before do
    allow(Shoryuken::Logging.logger).to receive(:info)
    allow(ProcessProbationMergeJob).to receive(:perform_later)
    allow(ProcessProbationUnmergeJob).to receive(:perform_later)
  end

  describe 'domain event registration' do
    it 'routes probation merge-related events to the probation merge handler' do
      expect(Rails.configuration.domain_event_handlers).to include(
        'probation-case.merge.completed' => 'DomainEvents::Handlers::ProbationMergeHandler',
        'probation-case.unmerge.completed' => 'DomainEvents::Handlers::ProbationMergeHandler',
      )
    end
  end

  context 'when handling a probation merge event and old CRN is tracked locally' do
    before do
      allow(ProbationMergeService).to receive(:locally_tracked?).with(old_crn).and_return(true)
    end

    it 'enqueues ProcessProbationMergeJob with CRNs and event type', :queueing do
      allow(ProcessProbationMergeJob).to receive(:perform_later).and_call_original

      expect { handler.handle(event) }
        .to have_enqueued_job(ProcessProbationMergeJob)
        .with(old_crn, new_crn, event_type:)
    end

    it 'logs start and success' do
      handler.handle(event)

      expect(Shoryuken::Logging.logger).to have_received(:info)
        .with(/event=domain_event_handle_start.*old_crn=#{old_crn}.*new_crn=#{new_crn}/)
      expect(Shoryuken::Logging.logger).to have_received(:info)
        .with(/event=domain_event_handle_success.*old_crn=#{old_crn}.*new_crn=#{new_crn}/)
    end

    it 'does not emit noop log' do
      handler.handle(event)

      expect(Shoryuken::Logging.logger).not_to have_received(:info).with(/event=domain_event_handle_noop/)
    end
  end

  context 'when handling a probation merge event and old CRN is not tracked locally' do
    before do
      allow(ProbationMergeService).to receive(:locally_tracked?).with(old_crn).and_return(false)
    end

    it 'does not enqueue ProcessProbationMergeJob' do
      handler.handle(event)

      expect(ProcessProbationMergeJob).not_to have_received(:perform_later)
    end

    it 'emits noop and success logs' do
      handler.handle(event)

      expect(Shoryuken::Logging.logger).to have_received(:info)
        .with(/event=domain_event_handle_noop.*old_crn=#{old_crn}.*new_crn=#{new_crn}/)
      expect(Shoryuken::Logging.logger).to have_received(:info)
        .with(/event=domain_event_handle_success.*old_crn=#{old_crn}.*new_crn=#{new_crn}/)
    end
  end

  context 'when handling a probation unmerge event' do
    let(:event_type) { 'probation-case.unmerge.completed' }
    let(:event) do
      DomainEvents::Event.new(
        event_type:,
        version: 1,
        description: 'A probation case unmerge has completed',
        additional_information: {
          'reactivatedCRN' => old_crn,
          'unmergedCRN' => new_crn,
        },
        external_event: true,
      )
    end

    context 'when merge mapping is tracked locally' do
      before do
        allow(ProbationUnmergeService).to receive(:locally_tracked?).with(old_crn:, new_crn:).and_return(true)
      end

      it 'enqueues ProcessProbationUnmergeJob with CRNs and event type', :queueing do
        allow(ProcessProbationUnmergeJob).to receive(:perform_later).and_call_original

        expect { handler.handle(event) }
          .to have_enqueued_job(ProcessProbationUnmergeJob)
          .with(old_crn, new_crn, event_type:)
      end
    end

    context 'when merge mapping is not tracked locally' do
      before do
        allow(ProbationUnmergeService).to receive(:locally_tracked?).with(old_crn:, new_crn:).and_return(false)
      end

      it 'does not enqueue ProcessProbationUnmergeJob and emits noop' do
        handler.handle(event)

        aggregate_failures do
          expect(ProcessProbationUnmergeJob).not_to have_received(:perform_later)
          expect(Shoryuken::Logging.logger).to have_received(:info)
            .with(/event=domain_event_handle_noop.*Merge mapping not tracked locally/)
          expect(Shoryuken::Logging.logger).to have_received(:info)
            .with(/event=domain_event_handle_success.*old_crn=#{old_crn}.*new_crn=#{new_crn}/)
        end
      end
    end
  end
end
