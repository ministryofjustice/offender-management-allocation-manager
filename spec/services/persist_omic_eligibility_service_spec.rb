# frozen_string_literal: true

require 'rails_helper'

describe 'PersistOmicEligibilityService' do
  subject(:service) { PersistOmicEligibilityService.new }

  before do
    eligible_offenders = [
      build(:nomis_offender, :inside_omic_policy, prisonerNumber: 'G1234AB'),
      build(:nomis_offender, :inside_omic_policy, prisonerNumber: 'G1234AC'),
    ]
    ineligible_offenders = [
      build(:nomis_offender, :outside_omic_policy, prisonerNumber: 'G1234AD'),
      build(:nomis_offender, :outside_omic_policy, prisonerNumber: 'G1234AE'),
      build(:nomis_offender, :outside_omic_policy, prisonerNumber: 'G1234AF'),
    ]
    stub_offenders_for_prison('LEI', eligible_offenders + ineligible_offenders)
  end

  def eligibility_of(nomis_offender_id) = OmicEligibility.find_by(nomis_offender_id:)&.eligible

  describe '#call' do
    context 'when processing offenders for a prison' do
      before do
        allow(PrisonService).to receive(:prison_codes).and_return(%w[LEI])
      end

      it 'calls the bulk offender API with the expected arguments' do
        expect(HmppsApi::PrisonApi::OffenderApi)
          .to receive(:get_offenders_in_prison)
          .with(
            'LEI',
            fetch_complexities: false,
            fetch_categories: false,
            fetch_movements: false
          )
          .and_call_original

        service.call
      end

      it 'persists offenders inside omic policy as eligible' do
        service.call

        expect(eligibility_of('G1234AB')).to eq(true)
        expect(eligibility_of('G1234AC')).to eq(true)
      end

      it 'persists offenders outside omic policy as not eligible' do
        service.call

        expect(eligibility_of('G1234AD')).to eq(false)
        expect(eligibility_of('G1234AE')).to eq(false)
        expect(eligibility_of('G1234AF')).to eq(false)
      end

      it 'updates updated_at when values change' do
        existing_record_that_doesnt_change_value = create(:omic_eligibility, nomis_offender_id: 'G1234AB', eligible: true, updated_at: 1.day.ago)
        existing_record_that_does_change_value = create(:omic_eligibility, nomis_offender_id: 'G1234AC', eligible: false, updated_at: 1.day.ago)
        previous_updated_at1 = existing_record_that_doesnt_change_value.updated_at
        previous_updated_at2 = existing_record_that_does_change_value.updated_at

        service.call

        expect(existing_record_that_doesnt_change_value.reload.updated_at).to be >= previous_updated_at1
        expect(existing_record_that_does_change_value.reload.updated_at).to be > previous_updated_at2
      end
    end

    context 'when a prison has no offenders' do
      it 'handles empty results without creating records' do
        allow(PrisonService).to receive(:prison_codes).and_return(%w[MDI])
        stub_offenders_for_prison('MDI', [])

        expect { service.call }.not_to raise_error
        expect(OmicEligibility.count).to eq(0)
      end
    end
  end

  describe '#call cleanup' do
    before do
      allow(PrisonService).to receive(:prison_codes).and_return(%w[LEI])
    end

    it 'deletes offenders missing from the current prison run' do
      create(:omic_eligibility, nomis_offender_id: 'X0000AA', eligible: true, prison: 'LEI')
      stub_offenders_for_prison('LEI', [])

      service.call

      expect(OmicEligibility.find_by(nomis_offender_id: 'X0000AA')).to be_nil
    end

    it 'skips cleanup when a prison fetch fails' do
      create(:omic_eligibility, nomis_offender_id: 'X0000AA', eligible: true, prison: 'LEI')
      allow(HmppsApi::PrisonApi::OffenderApi).to receive(:get_offenders_in_prison).and_raise(StandardError, 'boom')

      service.call

      expect(OmicEligibility.find('X0000AA').prison).to eq('LEI')
    end

    it 'handles offenders moved between managed prisons without deleting them' do
      moved_offender = build(:nomis_offender, :inside_omic_policy, prisonerNumber: 'G9999ZZ')

      create(:omic_eligibility, nomis_offender_id: 'G9999ZZ', eligible: true, prison: 'LEI')

      allow(PrisonService).to receive(:prison_codes).and_return(%w[LEI MDI])
      stub_offenders_for_prison('LEI', [])
      stub_offenders_for_prison('MDI', [moved_offender])

      service.call

      record = OmicEligibility.find('G9999ZZ')
      expect(record.prison).to eq('MDI')
      expect(record.eligible).to be(true)
    end

    it 'logs when rows exist for prisons outside the authoritative prison list' do
      create(:omic_eligibility, nomis_offender_id: 'X1111AA', eligible: true, prison: 'ZZZ')
      allow(PersistOmicEligibilityService.logger).to receive(:info)

      expect(PersistOmicEligibilityService.logger)
        .to receive(:info)
        .with(include('status=orphaned_prison_rows_detected', 'prisons=ZZZ'))

      service.call
    end
  end
end
