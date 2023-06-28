RSpec.describe DomainEvents::EventFactory do
  let(:event) { instance_double DomainEvents::Event, :event }

  before do
    allow(DomainEvents::Event).to receive(:new).and_return(event)
  end

  it 'builds handover events' do
    response = described_class.build_handover_event(noms_number: 'X1111XX', host: 'https://example.com')

    expect(response).to eq event
    expect(DomainEvents::Event).to have_received(:new).with(
      event_type: 'handover.changed',
      version: 1,
      description: 'Handover date and/or responsibility was updated',
      detail_url: 'https://example.com/handovers/X1111XX',
      noms_number: 'X1111XX',
    )
  end
end
