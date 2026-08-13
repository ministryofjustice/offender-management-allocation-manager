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

  describe '#call missing-runs cleanup' do
    before do
      allow(PrisonService).to receive(:prison_codes).and_return(%w[LEI])
    end

    it 'increments missing_runs_count on first missing pass without deleting' do
      create(:omic_eligibility, nomis_offender_id: 'X0000AA', eligible: true, prison: 'LEI', missing_runs_count: 0)
      stub_offenders_for_prison('LEI', [])

      service.call

      expect(OmicEligibility.find('X0000AA').missing_runs_count).to eq(1)
    end

    it 'deletes on second consecutive missing pass' do
      create(:omic_eligibility, nomis_offender_id: 'X0000AA', eligible: true, prison: 'LEI', missing_runs_count: 1)
      stub_offenders_for_prison('LEI', [])

      service.call

      expect(OmicEligibility.find_by(nomis_offender_id: 'X0000AA')).to be_nil
    end

    it 'resets missing_runs_count to zero when offender reappears' do
      create(:omic_eligibility, nomis_offender_id: 'G1234AB', eligible: true, prison: 'LEI', missing_runs_count: 1)

      service.call

      expect(OmicEligibility.find('G1234AB').missing_runs_count).to eq(0)
    end

    it 'skips missing/deletion cleanup when a prison fetch fails' do
      create(:omic_eligibility, nomis_offender_id: 'X0000AA', eligible: true, prison: 'LEI', missing_runs_count: 1)
      allow(HmppsApi::PrisonApi::OffenderApi).to receive(:get_offenders_in_prison).and_raise(StandardError, 'boom')

      service.call

      expect(OmicEligibility.find('X0000AA').missing_runs_count).to eq(1)
    end

    it 'handles offenders moved between managed prisons without deleting them' do
      moved_offender = build(:nomis_offender, :inside_omic_policy, prisonerNumber: 'G9999ZZ')

      # Existing row still points to old prison and is already at first-miss threshold.
      create(:omic_eligibility, nomis_offender_id: 'G9999ZZ', eligible: true, prison: 'LEI', missing_runs_count: 1)

      allow(PrisonService).to receive(:prison_codes).and_return(%w[LEI MDI])
      stub_offenders_for_prison('LEI', [])
      stub_offenders_for_prison('MDI', [moved_offender])

      service.call

      record = OmicEligibility.find('G9999ZZ')
      expect(record.prison).to eq('MDI')
      expect(record.missing_runs_count).to eq(0)
      expect(record.eligible).to be(true)
    end

    it 'logs when rows exist for prisons outside the authoritative prison list' do
      create(:omic_eligibility, nomis_offender_id: 'X1111AA', eligible: true, prison: 'ZZZ', missing_runs_count: 0)
      allow(PersistOmicEligibilityService.logger).to receive(:info)

      expect(PersistOmicEligibilityService.logger)
        .to receive(:info)
        .with(include('status=orphaned_prison_rows_detected', 'prisons=ZZZ'))

      service.call
    end

    it 'logs how many rows are pending deletion in future runs' do
      create(:omic_eligibility, nomis_offender_id: 'X1111AA', eligible: true, prison: 'LEI', missing_runs_count: 0)
      create(:omic_eligibility, nomis_offender_id: 'X1111AB', eligible: true, prison: 'LEI', missing_runs_count: 1)
      allow(PersistOmicEligibilityService.logger).to receive(:info)

      expect(PersistOmicEligibilityService.logger)
        .to receive(:info)
        .with(include('status=cleanup_pending', 'threshold=2', 'due_now=1', 'due_next_run=1'))

      service.call
    end
  end
end
