# frozen_string_literal: true

RSpec.describe ProcessPrisonerStatusJob, type: :job do
  let(:nomis_offender_id) { 'A1234BC' }
  let(:allocation) { instance_double(AllocationHistory, deallocate_primary_pom: true, deallocate_secondary_pom: true) }
  let(:active_allocations) { double('active_allocations') }
  let(:offender) { double('Offender', offender_no: nomis_offender_id, legal_status:, prison_id:, 'in_womens_prison?': in_womens_prison, sentenced?: sentenced, immigration_case?: immigration_case) }
  let(:legal_status) { 'SENTENCED' }
  let(:prison_id) { 'LEI' }
  let(:in_womens_prison) { false }
  let(:sentenced) { true }
  let(:immigration_case) { false }

  before do
    allow(AllocationHistory).to receive(:active).and_return(active_allocations)
    allow(active_allocations).to receive(:find_by).with(nomis_offender_id:).and_return(allocation)
    allow(HmppsApi::ComplexityApi).to receive(:inactivate)

    allow(HmppsApi::PrisonApi::OffenderApi).to receive(:get_offender).with(
      nomis_offender_id,
      ignore_legal_status: true,
      fetch_complexities: false,
      fetch_categories: false,
      fetch_movements: false,
      cache: false,
    ).and_return(offender)
  end

  context 'when allocation is not found' do
    let(:allocation) { nil }

    it 'still checks whether complexity should be inactivated' do
      expect(HmppsApi::PrisonApi::OffenderApi).to receive(:get_offender).and_return(offender)
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

  context 'when offender is unsentenced in a women\'s prison' do
    let(:allocation) { nil }
    let(:legal_status) { 'REMAND' }
    let(:prison_id) { 'AGI' }
    let(:sentenced) { false }

    let(:in_womens_prison) { true }

    it 'inactivates complexity even without an active allocation' do
      expect(HmppsApi::ComplexityApi).to receive(:inactivate).with(nomis_offender_id)

      described_class.perform_now(nomis_offender_id)
    end
  end

  context 'when offender is an immigration case in a women\'s prison' do
    let(:allocation) { nil }
    let(:legal_status) { 'IMMIGRATION_DETAINEE' }
    let(:prison_id) { 'AGI' }
    let(:sentenced) { false }
    let(:immigration_case) { true }

    let(:in_womens_prison) { true }

    it 'does not inactivate complexity' do
      expect(HmppsApi::ComplexityApi).not_to receive(:inactivate)

      described_class.perform_now(nomis_offender_id)
    end
  end

  context 'when offender is unsentenced in a male prison' do
    let(:allocation) { nil }
    let(:legal_status) { 'REMAND' }
    let(:sentenced) { false }

    it 'does not inactivate complexity' do
      expect(HmppsApi::ComplexityApi).not_to receive(:inactivate)

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

  context 'when offender legal_status is unknown' do
    let(:legal_status) { 'UNKNOWN' }

    it 'does not deallocate POMs or inactivate complexity' do
      expect(allocation).not_to receive(:deallocate_primary_pom)
      expect(allocation).not_to receive(:deallocate_secondary_pom)
      expect(HmppsApi::ComplexityApi).not_to receive(:inactivate)

      described_class.perform_now(nomis_offender_id)
    end
  end
end
