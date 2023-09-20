RSpec.describe DomainEvents::Handlers::ProbationChangeHandler do
  subject!(:handler) { described_class.new }

  before do
    stub_const('ENABLE_EVENT_BASED_PROBATION_CHANGE', true)
    allow(ProcessDeliusDataJob).to receive(:perform_now)
    expect(ProcessDeliusDataJob).not_to receive(:perform_later)
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
        expect(ProcessDeliusDataJob).to have_received(:perform_now).with(crn, identifier_type: :crn)
      end
    end

    context 'with cases whose registration type does not includes MAPP, DASO, INVI' do
      let(:register_type) { 'BOBBINS' }

      it 'does not update case information' do
        handler.handle(event)
        expect(ProcessDeliusDataJob).not_to have_received(:perform_now).with('FIXME')
      end
    end
  end
end
