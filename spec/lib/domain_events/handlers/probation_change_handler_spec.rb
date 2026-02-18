RSpec.describe DomainEvents::Handlers::ProbationChangeHandler do
  subject!(:handler) { described_class.new }

  before do
    allow(ProcessDeliusDataJob).to receive(:perform_now)
    allow(DebouncedProcessDeliusDataJob).to receive(:set).and_return(DebouncedProcessDeliusDataJob)
    allow(DebouncedProcessDeliusDataJob).to receive(:perform_later)
    allow(Shoryuken::Logging.logger).to receive(:info).and_return(nil)
  end

  let(:event) do
    DomainEvents::Event.new(
      event_type: event_type,
      version: 1,
      description: 'A fabulous description',
      detail_url: 'https://example.org/irrelevant',
      additional_information: additional_information,
      crn_number: crn,
      external_event: true
    )
  end

  let(:crn) { 'X08769' }

  shared_examples 'debounced probation update' do
    it 'updates case information' do
      handler.handle(event)
      expect(DebouncedProcessDeliusDataJob).to have_received(:set).with(wait: described_class::DEBOUNCE_WINDOW)
      expect(DebouncedProcessDeliusDataJob).to have_received(:perform_later).with(
        crn, event_type:, debounce_key: "domain_events:probation_change:#{crn}", debounce_token: kind_of(String)
      )
    end
  end

  context 'with event type probation-case.registration.*' do
    let(:event_type) { 'probation-case.registration.added' }

    let(:additional_information) do
      { 'registerTypeCode' => register_type }
    end

    context 'with cases whose registration type includes MAPP, DASO, INVI' do
      let(:register_type) { 'MAPP' }

      include_examples 'debounced probation update'
    end

    context 'with cases whose registration type does not includes MAPP, DASO, INVI' do
      let(:register_type) { 'BOBBINS' }

      before { handler.handle(event) }

      it 'does not update case information' do
        expect(DebouncedProcessDeliusDataJob).not_to have_received(:perform_later)
      end

      it 'emits a noop log info message' do
        expect(Shoryuken::Logging.logger).to have_received(:info).with(/domain_event_handle_noop/).once
      end
    end
  end

  %w[OFFENDER_MANAGER_CHANGED OFFENDER_OFFICER_CHANGED OFFENDER_DETAILS_CHANGED].each do |event_type_value|
    context "with event type #{event_type_value}" do
      let(:event_type) { event_type_value }
      let(:additional_information) { {} }

      include_examples 'debounced probation update'
    end
  end
end
