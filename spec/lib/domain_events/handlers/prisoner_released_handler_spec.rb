RSpec.describe DomainEvents::Handlers::PrisonerReleasedHandler do
  subject!(:handler) { described_class.new }

  let(:nomis_offender_id) { 'T1111XX' }
  let(:case_information) { double(:case_information) }

  let(:event) do
    DomainEvents::Event.new(
      event_type: 'prisoner-offender-search.prisoner.released',
      version: 1,
      description: 'A prisoner has been released from a prison',
      detail_url: 'https://example.org/irrelevant',
      additional_information: {
        'nomsNumber' => 'T1111XX',
        'reason' => reason,
      },
      external_event: true,
    )
  end

  before do
    allow(ProcessPrisonerReleaseJob).to receive(:perform_later)
    allow(CaseInformation).to receive(:find_by).with(nomis_offender_id:).and_return(case_information)
  end

  context 'when the reason is RELEASED' do
    let(:reason) { 'RELEASED' }

    it 'enqueues the job' do
      expect(ProcessPrisonerReleaseJob).to receive(:perform_later).with(nomis_offender_id)
      handler.handle(event)
    end
  end

  context 'when the reason is TRANSFERRED' do
    let(:reason) { 'TRANSFERRED' }

    it 'enqueues the job' do
      expect(ProcessPrisonerReleaseJob).to receive(:perform_later).with(nomis_offender_id)
      handler.handle(event)
    end
  end

  context 'when the reason is RELEASED_TO_HOSPITAL' do
    let(:reason) { 'RELEASED_TO_HOSPITAL' }

    it 'does not enqueue the job' do
      expect(ProcessPrisonerReleaseJob).not_to receive(:perform_later)
      handler.handle(event)
    end
  end

  context 'when the reason is any other not handled' do
    let(:reason) { 'SENT_TO_COURT' }

    it 'does not enqueue the job' do
      expect(ProcessPrisonerReleaseJob).not_to receive(:perform_later)
      handler.handle(event)
    end
  end
end
