RSpec.describe DomainEvents::Handlers::PrisonerUpdatedHandler do
  subject!(:handler) { described_class.new }

  before do
    allow(RecalculateHandoverDateJob).to receive(:perform_now)
    allow(RecalculateHandoverDateJob).to receive(:perform_later)

    allow(CaseInformation).to receive(:find_by_nomis_offender_id).and_return(double(:case_information))
  end

  it 'does not recalculate handover for cases whose categoriesChanged includes SENTENCE' do
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
    
    expect(RecalculateHandoverDateJob).not_to have_received(:perform_now)
    expect(RecalculateHandoverDateJob).not_to have_received(:perform_later)
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

    expect(RecalculateHandoverDateJob).not_to have_received(:perform_now)
    expect(RecalculateHandoverDateJob).not_to have_received(:perform_later)
  end

  it 'does NOT proceed for cases that have no Delius probation case information' do
    allow(CaseInformation).to receive(:find_by_nomis_offender_id).and_return(nil)

    event = DomainEvents::Event.new(
      event_type: 'prisoner-offender-search.prisoner.updated',
      version: 1,
      description: 'A prisoner record has been updated',
      detail_url: 'https://example.org/irrelevant',
      additional_information: {
        'nomsNumber' => 'T1111XX',
        'categoriesChanged' => %w[SENTENCE],
      },
      external_event: true,
    )
    handler.handle(event)

    expect(RecalculateHandoverDateJob).not_to have_received(:perform_now)
    expect(RecalculateHandoverDateJob).not_to have_received(:perform_later)
  end
end
