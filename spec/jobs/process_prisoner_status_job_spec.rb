# frozen_string_literal: true

RSpec.describe ProcessPrisonerStatusJob, type: :job do
  let(:nomis_offender_id) { 'A1234BC' }
  let(:allocation) { instance_double(AllocationHistory, deallocate_primary_pom: true, deallocate_secondary_pom: true) }
  let(:active_allocations) { double('active_allocations') }
  let(:offender) { double('Offender', legal_status:) }
  let(:legal_status) { 'SENTENCED' }

  before do
    allow(AllocationHistory).to receive(:active).and_return(active_allocations)
    allow(active_allocations).to receive(:find_by).with(nomis_offender_id:).and_return(allocation)

    allow(HmppsApi::PrisonApi::OffenderApi).to receive(:get_offender).with(
      nomis_offender_id,
      ignore_legal_status: true,
      fetch_complexities: false,
      fetch_categories: false,
      fetch_movements: false
    ).and_return(offender)
  end

  context 'when allocation is not found' do
    let(:allocation) { nil }

    it 'does nothing' do
      expect(HmppsApi::PrisonApi::OffenderApi).not_to receive(:get_offender)
      described_class.perform_now(nomis_offender_id)
    end
  end

  context 'when offender is not found' do
    let(:offender) { nil }

    it 'logs an error and does not deallocate' do
      expect(Rails.logger).to receive(:error)
      expect(allocation).not_to receive(:deallocate_primary_pom)
      described_class.perform_now(nomis_offender_id)
    end
  end

  context 'when offender legal_status is blank' do
    let(:legal_status) { '' }

    it 'logs an error and does not deallocate' do
      expect(Rails.logger).to receive(:error)
      expect(allocation).not_to receive(:deallocate_primary_pom)
      described_class.perform_now(nomis_offender_id)
    end
  end

  context 'when offender legal_status is not allowed' do
    let(:legal_status) { 'REMAND' }

    it 'deallocates POMs' do
      expect(allocation).to receive(:deallocate_primary_pom).with(event_trigger: AllocationHistory::LEGAL_STATUS_CHANGED)
      expect(allocation).to receive(:deallocate_secondary_pom).with(event_trigger: AllocationHistory::LEGAL_STATUS_CHANGED)

      described_class.perform_now(nomis_offender_id)
    end
  end

  context 'when offender legal_status is allowed' do
    let(:legal_status) { 'SENTENCED' }

    it 'does not deallocate POMs' do
      expect(allocation).not_to receive(:deallocate_primary_pom)
      expect(allocation).not_to receive(:deallocate_secondary_pom)

      described_class.perform_now(nomis_offender_id)
    end
  end
end
