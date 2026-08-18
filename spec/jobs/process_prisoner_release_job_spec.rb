# frozen_string_literal: true

RSpec.describe ProcessPrisonerReleaseJob, type: :job do
  let(:nomis_offender_id) { 'A1234BC' }
  let!(:prison) { Prison.find_by(code: 'LEI') || create(:prison, code: 'LEI') }

  before do
    allow(MovementService).to receive(:process_offender_last_movement)
  end

  it 'delegates release handling to MovementService' do
    expect(MovementService).to receive(:process_offender_last_movement).with(nomis_offender_id)
    described_class.perform_now(nomis_offender_id)
  end

  context 'when movement processing does not find a releasable movement' do
    before do
      allow(MovementService).to receive(:process_offender_last_movement).and_return(false)
    end

    it 'still routes processing through MovementService without raising' do
      expect(MovementService).to receive(:process_offender_last_movement).with(nomis_offender_id)
      described_class.perform_now(nomis_offender_id)
    end
  end

  context 'when performing a release' do
    let(:last_movement) do
      build(:movement,
            offenderNo: nomis_offender_id,
            directionCode: 'OUT',
            movementType: 'REL',
            toAgency: 'OUT',
            fromAgency: from_agency)
    end
    let(:timeline) { instance_double(HmppsApi::PrisonTimeline, last_movement:) }
    let(:from_agency) { 'LEI' }

    before do
      allow(MovementService).to receive(:process_offender_last_movement).and_call_original
      allow(HmppsApi::PrisonApi::MovementApi).to receive(:movements_for)
        .with(nomis_offender_id, movement_types: [], cache: false)
        .and_return(timeline)

      stub_pom(
        build(:pom, staffId: 485_926, firstName: 'MOIC', lastName: 'POM', primaryEmail: 'test@example.com')
      )
      stub_offender(
        build(:nomis_offender, prisonerNumber: nomis_offender_id, prisonId: 'OUT', firstName: 'John', lastName: 'Doe')
      )
    end

    it 'cleans up local state via MovementService and OffenderReleasedService' do
      offender = create(:offender, nomis_offender_id:)
      allocation = create(:allocation_history, prison: 'LEI', nomis_offender_id: offender.nomis_offender_id)
      create(:case_information, offender:)
      create(:omic_eligibility, nomis_offender_id: offender.nomis_offender_id)

      described_class.perform_now(nomis_offender_id)

      expect(allocation.reload.active?).to be false
      expect(CaseInformation.find_by(nomis_offender_id:)).to be_nil
      expect(OmicEligibility.find_by(nomis_offender_id:)).to be_nil
    end

    context 'when the offender has already been cleaned up by another path' do
      let(:from_agency) { 'AGI' }

      it 'does not fail and skips duplicate release side effects' do
        expect(HmppsApi::ComplexityApi).not_to receive(:inactivate)

        expect { described_class.perform_now(nomis_offender_id) }.not_to raise_error
      end
    end
  end
end
