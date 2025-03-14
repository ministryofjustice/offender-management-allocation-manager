RSpec.describe DomainEvents::Handlers::ProbationChangeHandler do
  subject!(:handler) { described_class.new }

  before do
    allow(ProcessDeliusDataJob).to receive(:perform_now)
    expect(ProcessDeliusDataJob).not_to receive(:perform_later)
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

  context 'with event type probation-case.registration.*' do
    let(:event_type) { 'probation-case.registration.added' }

    let(:additional_information) do
      { 'registerTypeCode' => register_type }
    end

    context 'with cases whose registration type includes MAPP, DASO, INVI' do
      let(:register_type) { 'MAPP' }

      it 'updates case information' do
        handler.handle(event)
        expect(ProcessDeliusDataJob).to have_received(:perform_now).with(
          crn, identifier_type: :crn, trigger_method: :event, event_type:
        )
      end
    end

    context 'with cases whose registration type does not includes MAPP, DASO, INVI' do
      let(:register_type) { 'BOBBINS' }

      before { handler.handle(event) }

      it 'does not update case information' do
        expect(ProcessDeliusDataJob).not_to have_received(:perform_now)
      end

      it 'emits a noop log info message' do
        expect(Shoryuken::Logging.logger).to have_received(:info).with(/domain_event_handle_noop/).once
      end
    end
  end

  context 'with event type OFFENDER_MANAGER_CHANGED' do
    let(:event_type) { 'OFFENDER_MANAGER_CHANGED' }
    let(:additional_information) { {} }

    it 'updates case information' do
      handler.handle(event)
      expect(ProcessDeliusDataJob).to have_received(:perform_now).with(
        crn, identifier_type: :crn, trigger_method: :event, event_type:
      )
    end
  end

  context 'with event type OFFENDER_OFFICER_CHANGED' do
    let(:event_type) { 'OFFENDER_OFFICER_CHANGED' }
    let(:additional_information) { {} }

    it 'updates case information' do
      handler.handle(event)
      expect(ProcessDeliusDataJob).to have_received(:perform_now).with(
        crn, identifier_type: :crn, trigger_method: :event, event_type:
      )
    end
  end

  context 'with event type OFFENDER_DETAILS_CHANGED' do
    let(:event_type) { 'OFFENDER_DETAILS_CHANGED' }
    let(:additional_information) { {} }

    it 'updates case information' do
      handler.handle(event)
      expect(ProcessDeliusDataJob).to have_received(:perform_now).with(
        crn, identifier_type: :crn, trigger_method: :event, event_type:
      )
    end
  end
end
