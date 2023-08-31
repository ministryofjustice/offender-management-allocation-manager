RSpec.describe DomainEvents::Handlers::PrisonerUpdatedHandler do
  subject!(:handler) { described_class.new }

  before do
    stub_const('ENABLE_EVENT_BASED_HANDOVER_CALCULATION', true)
    allow(RecalculateHandoverDateJob).to receive(:perform_now)
    expect(RecalculateHandoverDateJob).not_to receive(:perform_later)
  end

  it 'recalculates handover for cases whose categoriesChanged includes SENTENCE' do
    event = DomainEvents::Event.new(
      event_type: 'prisoner-offender-search.prisoner.updated',
      version: 1,
      description: 'A prisoner record has been updated',
      detail_url: 'https://example.org/irrelevant',
      additional_information: {
        'nomsNumber' => 'T1111XX',
        'categoriesChanged' => %w[STATUS SENTENCE],
      },
      external_event: true,
    )
    handler.handle(event)

    expect(RecalculateHandoverDateJob).to have_received(:perform_now).with('T1111XX')
  end

  it 'does not recalculate handover for cases whose categoriesChanged does not SENTENCE' do
    event = DomainEvents::Event.new(
      event_type: 'prisoner-offender-search.prisoner.updated',
      version: 1,
      description: 'A prisoner record has been updated',
      detail_url: 'https://example.org/irrelevant',
      additional_information: {
        'nomsNumber' => 'T1111XX',
        'categoriesChanged' => %w[PERSONAL_DETAILS STATUS],
      },
      external_event: true,
    )
    handler.handle(event)

    expect(RecalculateHandoverDateJob).not_to have_received(:perform_now).with('T1111XX')
  end
end
