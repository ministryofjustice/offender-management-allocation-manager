RSpec.describe DomainEvents::Handlers::PrisonerUpdatedHandler do
  subject!(:handler) { described_class.new }

  let(:nomis_offender_id) { 'T1111XX' }
  let(:debounced_job_proxy) { instance_double(ActiveJob::ConfiguredJob, perform_later: nil) }
  let(:debounced_status_job_proxy) { instance_double(ActiveJob::ConfiguredJob, perform_later: nil) }

  before do
    allow(DebouncedProcessPrisonerStatusJob).to receive(:set).and_return(debounced_status_job_proxy)
    allow(DebouncedRecalculateHandoverDateJob).to receive(:set).and_return(debounced_job_proxy)
  end

  def build_event(categories_changed:)
    DomainEvents::Event.new(
      event_type: 'prisoner-offender-search.prisoner.updated',
      version: 1,
      description: 'A prisoner record has been updated',
      detail_url: 'https://example.org/irrelevant',
      additional_information: {
        'nomsNumber' => nomis_offender_id,
        'categoriesChanged' => categories_changed,
      },
      external_event: true,
    )
  end

  describe 'legal status processing' do
    it 'does not process legal status changes unless categoriesChanged includes STATUS' do
      handler.handle(build_event(categories_changed: %w[SENTENCE]))

      expect(DebouncedProcessPrisonerStatusJob).not_to have_received(:set)
    end

    it 'processes legal status changes when categoriesChanged includes STATUS and local case information exists' do
      create(:case_information, offender: create(:offender, nomis_offender_id:))

      handler.handle(build_event(categories_changed: %w[PERSONAL_DETAILS STATUS]))

      expect(DebouncedProcessPrisonerStatusJob).to have_received(:set).with(wait: described_class::STATUS_DEBOUNCE_WINDOW)
    end

    it 'does not process legal status changes for offenders without local case information' do
      handler.handle(build_event(categories_changed: %w[STATUS]))

      expect(DebouncedProcessPrisonerStatusJob).not_to have_received(:set)
    end

    it 'writes a status debounce token to the cache' do
      create(:case_information, offender: create(:offender, nomis_offender_id:))

      handler.handle(build_event(categories_changed: %w[STATUS]))

      cached_token = Rails.cache.read("domain_events:prisoner_updated_status:#{nomis_offender_id}")
      expect(cached_token).to be_present
    end
  end

  describe 'debounced handover recalculation' do
    context 'when the offender has an existing calculated handover date' do
      before do
        offender = create(:offender, nomis_offender_id:)
        create(:calculated_handover_date, offender:)
      end

      it 'triggers debounced recalculation when categoriesChanged includes SENTENCE' do
        handler.handle(build_event(categories_changed: %w[SENTENCE]))

        expect(DebouncedRecalculateHandoverDateJob).to have_received(:set).with(wait: 1.hour)
      end

      it 'does not trigger debounced recalculation for non-SENTENCE categories' do
        handler.handle(build_event(categories_changed: %w[STATUS LOCATION PERSONAL_DETAILS]))

        expect(DebouncedRecalculateHandoverDateJob).not_to have_received(:set)
      end

      it 'triggers both status processing and debounced recalculation for STATUS and SENTENCE' do
        create(:case_information, offender: Offender.find(nomis_offender_id))

        handler.handle(build_event(categories_changed: %w[STATUS SENTENCE]))

        expect(DebouncedProcessPrisonerStatusJob).to have_received(:set).with(wait: described_class::STATUS_DEBOUNCE_WINDOW)
        expect(DebouncedRecalculateHandoverDateJob).to have_received(:set).with(wait: described_class::SENTENCE_DEBOUNCE_WINDOW)
      end

      it 'writes a debounce token to the cache' do
        handler.handle(build_event(categories_changed: %w[SENTENCE]))

        cached_token = Rails.cache.read("domain_events:prisoner_updated_handover:#{nomis_offender_id}")
        expect(cached_token).to be_present
      end
    end

    it 'does not trigger debounced recalculation for offenders without an existing handover date' do
      handler.handle(build_event(categories_changed: %w[SENTENCE]))

      expect(DebouncedRecalculateHandoverDateJob).not_to have_received(:set)
    end
  end
end
