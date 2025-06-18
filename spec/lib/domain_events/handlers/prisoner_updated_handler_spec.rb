RSpec.describe DomainEvents::Handlers::PrisonerUpdatedHandler do
  subject!(:handler) { described_class.new }

  before do
    allow(ProcessPrisonerStatusJob).to receive(:perform_later)
    allow(CaseInformation).to receive(:find_by_nomis_offender_id).and_return(double(:case_information))
  end

  it 'does not process legal status changes unless categoriesChanged includes STATUS' do
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

    expect(ProcessPrisonerStatusJob).not_to have_received(:perform_later)
  end

  it 'process legal status changes when categoriesChanged includes STATUS' do
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

    expect(ProcessPrisonerStatusJob).to have_received(:perform_later)
  end
end
