# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ReconcileReleasedOffendersService do
  let(:prison) { create(:prison, code: 'LEI') }
  let!(:omic_eligibility_marker) { create_omic_eligibility('A0000AA') }

  before do
    allow(PrisonService).to receive(:prison_codes).and_return([prison.code])
    allow(HmppsApi::PrisonApi::OffenderApi).to receive(:offender_summaries_for)
      .and_return({})
    allow(ProcessPrisonerStatusJob).to receive(:perform_now)
    stub_pom(
      build(:pom, staffId: 485_926, firstName: 'MOIC', lastName: 'POM', primaryEmail: 'test@example.com')
    )
  end

  def create_omic_eligibility(nomis_offender_id, prison_code: prison.code)
    OmicEligibility.create!(nomis_offender_id:, eligible: true, prison: prison_code)
  end

  def offender_summary(
    prison_id:,
    last_prison_id: nil,
    legal_status: 'SENTENCED',
    restricted_patient: false,
    in_out_status: 'IN',
    last_movement_type_code: 'ADM'
  )
    {
      'prisonId' => prison_id,
      'lastPrisonId' => last_prison_id,
      'restrictedPatient' => restricted_patient,
      'legalStatus' => legal_status,
      'inOutStatus' => in_out_status,
      'lastMovementTypeCode' => last_movement_type_code
    }
  end

  def stub_summaries_for(nomis_offender_ids, summaries_by_id)
    allow(HmppsApi::PrisonApi::OffenderApi).to receive(:offender_summaries_for)
      .with(nomis_offender_ids.to_set, cache: false)
      .and_return(summaries_by_id)
  end

  def stub_released_from(prison_code, *nomis_offender_ids)
    summaries = nomis_offender_ids.index_with do
      offender_summary(prison_id: 'OUT', last_prison_id: prison_code, in_out_status: 'OUT', last_movement_type_code: 'REL')
    end
    stub_summaries_for(nomis_offender_ids, summaries)
  end

  def create_prison_context(offender, prison_code: prison.code, active: false)
    create(
      :allocation_history,
      *(active ? [:primary] : [:release]),
      nomis_offender_id: offender.nomis_offender_id,
      prison: prison_code
    )
  end

  describe '#call' do
    context 'when an offender is in OmicEligibility (still in a managed prison)' do
      it 'does not flag them for cleanup' do
        offender = create(:offender)
        create(:case_information, offender:)
        create_omic_eligibility(offender.nomis_offender_id)

        result = described_class.new(prison_codes: [prison.code]).call

        expect(result.released_ids).to be_empty
        expect(result.candidate_count).to eq(0)
      end
    end

    context 'when an offender is still present in OmicEligibility but marked ineligible' do
      it 'does not treat them as a release-cleanup candidate' do
        offender = create(:offender)
        create(:case_information, offender:)
        OmicEligibility.create!(nomis_offender_id: offender.nomis_offender_id, eligible: false, prison: prison.code)

        result = described_class.new(prison_codes: [prison.code]).call

        expect(result.released_ids).to be_empty
        expect(result.candidate_count).to eq(0)
      end
    end

    context 'when an offender has stint data, is absent from OmicEligibility, and prisoner-search confirms release' do
      let(:offender) { create(:offender) }

      before do
        create(:case_information, offender:)
        create_prison_context(offender)
        stub_released_from(prison.code, offender.nomis_offender_id)
      end

      it 'identifies them as orphaned' do
        result = described_class.new(prison_codes: [prison.code]).call

        expect(result.released_ids).to include(offender.nomis_offender_id)
        expect(result.candidate_count).to eq(1)
        expect(result.released_count).to eq(1)
        expect(result.skipped_count).to eq(0)
      end

      it 'does not destroy data in dry-run mode' do
        described_class.new(dry_run: true, prison_codes: [prison.code]).call

        expect(CaseInformation.find_by(nomis_offender_id: offender.nomis_offender_id)).to be_present
      end

      it 'destroys stint data when not in dry-run mode' do
        expect(PomMailer).not_to receive(:with)

        described_class.new(dry_run: false, prison_codes: [prison.code]).call

        expect(CaseInformation.find_by(nomis_offender_id: offender.nomis_offender_id)).to be_nil
      end
    end

    context 'when an offender has stint data, is absent from OmicEligibility, but prisoner-search does NOT confirm release (e.g. ROTL)' do
      let(:offender) { create(:offender) }

      before do
        create(:case_information, offender:)
        create_prison_context(offender)
        stub_summaries_for(
          [offender.nomis_offender_id],
          {
            offender.nomis_offender_id => offender_summary(prison_id: prison.code, legal_status: 'SENTENCED')
          }
        )
      end

      it 'does not release them' do
        described_class.new(dry_run: false, prison_codes: [prison.code]).call

        expect(CaseInformation.find_by(nomis_offender_id: offender.nomis_offender_id)).to be_present
      end
    end

    context 'when offender has disallowed legal status but is not OUT' do
      let(:offender) { create(:offender) }

      before do
        create(:case_information, offender:)
        create_prison_context(offender)
        stub_summaries_for(
          [offender.nomis_offender_id],
          {
            offender.nomis_offender_id => offender_summary(prison_id: prison.code, legal_status: 'REMAND')
          }
        )
      end

      it 'delegates to ProcessPrisonerStatusJob and does not prune stint data' do
        described_class.new(dry_run: false, prison_codes: [prison.code]).call

        expect(ProcessPrisonerStatusJob).to have_received(:perform_now)
          .with(offender.nomis_offender_id, trigger_method: :reconcile)
        expect(CaseInformation.find_by(nomis_offender_id: offender.nomis_offender_id)).to be_present
      end
    end

    context 'when offender is OUT but marked as restricted patient' do
      let(:offender) { create(:offender) }

      before do
        create(:case_information, offender:)
        create_prison_context(offender)
        stub_summaries_for(
          [offender.nomis_offender_id],
          {
            offender.nomis_offender_id => offender_summary(
              prison_id: 'OUT',
              last_prison_id: prison.code,
              restricted_patient: true
            )
          }
        )
      end

      it 'does not prune and does not run legal-status processing' do
        described_class.new(dry_run: false, prison_codes: [prison.code]).call

        expect(ProcessPrisonerStatusJob).not_to have_received(:perform_now)
        expect(CaseInformation.find_by(nomis_offender_id: offender.nomis_offender_id)).to be_present
      end
    end

    context 'when offender is temporarily OUT on ROTL' do
      let(:offender) { create(:offender) }

      before do
        create(:case_information, offender:)
        create_prison_context(offender)
        stub_summaries_for(
          [offender.nomis_offender_id],
          {
            offender.nomis_offender_id => offender_summary(
              prison_id: 'OUT',
              last_prison_id: prison.code,
              in_out_status: 'OUT',
              last_movement_type_code: HmppsApi::MovementType::TEMPORARY
            )
          }
        )
      end

      it 'does not prune and does not run legal-status processing' do
        described_class.new(dry_run: false, prison_codes: [prison.code]).call

        expect(ProcessPrisonerStatusJob).not_to have_received(:perform_now)
        expect(CaseInformation.find_by(nomis_offender_id: offender.nomis_offender_id)).to be_present
      end
    end

    context 'when offender legal status is UNKNOWN and they are not OUT' do
      let(:offender) { create(:offender) }

      before do
        create(:case_information, offender:)
        create_prison_context(offender)
        stub_summaries_for(
          [offender.nomis_offender_id],
          {
            offender.nomis_offender_id => offender_summary(prison_id: prison.code, legal_status: 'UNKNOWN')
          }
        )
      end

      it 'delegates to ProcessPrisonerStatusJob and does not prune stint data' do
        described_class.new(dry_run: false, prison_codes: [prison.code]).call

        expect(ProcessPrisonerStatusJob).to have_received(:perform_now)
          .with(offender.nomis_offender_id, trigger_method: :reconcile)
        expect(CaseInformation.find_by(nomis_offender_id: offender.nomis_offender_id)).to be_present
      end
    end

    context 'when an offender has an active allocation and prisoner-search confirms release' do
      let(:offender) { create(:offender) }
      let!(:case_info) { create(:case_information, offender:) }
      let!(:allocation) do
        create(:allocation_history, :primary,
               nomis_offender_id: offender.nomis_offender_id,
               prison: prison.code)
      end

      before do
        stub_pom(build(:pom, staffId: 123_456, firstName: 'MOIC', lastName: 'POM', primaryEmail: 'test@example.com'))
        stub_offender(build(:nomis_offender, prisonerNumber: offender.nomis_offender_id, prisonId: 'OUT'))
        stub_released_from(prison.code, offender.nomis_offender_id)
      end

      it 'does not deallocate in dry-run mode' do
        described_class.new(dry_run: true, prison_codes: [prison.code]).call

        expect(allocation.reload.active?).to be true
      end

      it 'deallocates and destroys stint data when not in dry-run mode' do
        described_class.new(dry_run: false, prison_codes: [prison.code]).call

        allocation.reload
        expect(allocation.active?).to be false
        expect(allocation.event_trigger).to eq('offender_released')
        expect(CaseInformation.find_by(nomis_offender_id: offender.nomis_offender_id)).to be_nil
      end
    end

    context 'when multiple stint data types exist for an orphaned offender' do
      let(:offender) { create(:offender) }

      before do
        create(:case_information, offender:)
        create(:calculated_handover_date, offender:)
        create(:responsibility, offender:)
        create(:handover_progress_checklist, offender:)
        create_prison_context(offender)
        stub_released_from(prison.code, offender.nomis_offender_id)
      end

      it 'destroys all stint data when not in dry-run mode' do
        described_class.new(dry_run: false, prison_codes: [prison.code]).call

        expect(CaseInformation.find_by(nomis_offender_id: offender.nomis_offender_id)).to be_nil
        expect(CalculatedHandoverDate.find_by(nomis_offender_id: offender.nomis_offender_id)).to be_nil
        expect(Responsibility.find_by(nomis_offender_id: offender.nomis_offender_id)).to be_nil
        expect(HandoverProgressChecklist.find_by(nomis_offender_id: offender.nomis_offender_id)).to be_nil
      end
    end

    context 'when processing only a specific prison' do
      let(:other_prison) { create(:prison, code: 'MDI') }
      let(:offender_in_target_prison) { create(:offender) }
      let(:offender_in_other_prison) { create(:offender) }

      before do
        create(:case_information, offender: offender_in_target_prison)
        create(:case_information, offender: offender_in_other_prison)
        create_prison_context(offender_in_target_prison, prison_code: prison.code)
        create_prison_context(offender_in_other_prison, prison_code: other_prison.code)

        stub_summaries_for(
          [offender_in_target_prison.nomis_offender_id, offender_in_other_prison.nomis_offender_id],
          {
            offender_in_target_prison.nomis_offender_id => offender_summary(prison_id: 'OUT', last_prison_id: prison.code),
            offender_in_other_prison.nomis_offender_id => offender_summary(prison_id: other_prison.code, legal_status: 'SENTENCED')
          }
        )
      end

      it 'only processes releases confirmed from the target prison' do
        described_class.new(dry_run: false, prison_codes: [prison.code]).call

        expect(CaseInformation.find_by(nomis_offender_id: offender_in_target_prison.nomis_offender_id)).to be_nil
        expect(CaseInformation.find_by(nomis_offender_id: offender_in_other_prison.nomis_offender_id)).to be_present
      end
    end

    context 'when one prison has more candidates than the configured batch size' do
      let(:offender1) { create(:offender) }
      let(:offender2) { create(:offender) }

      before do
        create(:case_information, offender: offender1)
        create(:case_information, offender: offender2)
        create_prison_context(offender1)
        create_prison_context(offender2)

        stub_summaries_for(
          [offender1.nomis_offender_id],
          { offender1.nomis_offender_id => offender_summary(prison_id: 'OUT', last_prison_id: prison.code) }
        )
        stub_summaries_for(
          [offender2.nomis_offender_id],
          { offender2.nomis_offender_id => offender_summary(prison_id: prison.code, legal_status: 'SENTENCED') }
        )
      end

      it 'verifies release candidates in batches' do
        result = described_class.new(prison_codes: [prison.code], batch_size: 1).call

        expect(result.released_ids).to contain_exactly(offender1.nomis_offender_id)
        expect(result.skipped_count).to eq(1)
        expect(HmppsApi::PrisonApi::OffenderApi).to have_received(:offender_summaries_for)
          .with([offender1.nomis_offender_id].to_set, cache: false).at_least(:once)
        expect(HmppsApi::PrisonApi::OffenderApi).to have_received(:offender_summaries_for)
          .with([offender2.nomis_offender_id].to_set, cache: false).at_least(:once)
      end
    end

    context 'when prisoner-search call fails for one prison' do
      let(:other_prison) { create(:prison, code: 'MDI') }
      let(:offender) { create(:offender) }

      before do
        create(:case_information, offender:)
        create_prison_context(offender)
        allow(HmppsApi::PrisonApi::OffenderApi).to receive(:offender_summaries_for)
          .with([offender.nomis_offender_id].to_set, cache: false).and_raise(StandardError, 'API unavailable')
        allow(PrisonService).to receive(:prison_codes).and_return([prison.code, other_prison.code])
      end

      it 'continues processing remaining prisons without raising' do
        expect { described_class.new(dry_run: false).call }.not_to raise_error
      end
    end

    context 'when OffenderReleasedService raises for one offender' do
      let(:offender1) { create(:offender) }
      let(:offender2) { create(:offender) }

      before do
        create(:case_information, offender: offender1)
        create(:case_information, offender: offender2)
        create_prison_context(offender1)
        create_prison_context(offender2)
        stub_released_from(prison.code, offender1.nomis_offender_id, offender2.nomis_offender_id)

        allow(OffenderReleasedService).to receive(:release_offender)
          .with(offender1.nomis_offender_id, prison_code: prison.code, send_email: false).and_raise(StandardError, 'boom')
        allow(OffenderReleasedService).to receive(:release_offender)
          .with(offender2.nomis_offender_id, prison_code: prison.code, send_email: false).and_call_original
      end

      it 'continues processing remaining offenders' do
        described_class.new(dry_run: false, prison_codes: [prison.code]).call

        expect(CaseInformation.find_by(nomis_offender_id: offender1.nomis_offender_id)).to be_present
        expect(CaseInformation.find_by(nomis_offender_id: offender2.nomis_offender_id)).to be_nil
      end
    end

    context 'when an offender has stint data but no local prison context' do
      let(:offender) { create(:offender) }

      before do
        create(:case_information, offender:)
      end

      it 'queries prisoner-search summaries but leaves data untouched if unresolved' do
        expect(HmppsApi::PrisonApi::OffenderApi).to receive(:offender_summaries_for)
          .with([offender.nomis_offender_id].to_set, cache: false)
          .and_return({})

        result = described_class.new(dry_run: false, prison_codes: [prison.code]).call

        expect(result.released_ids).to be_empty
        expect(result.unresolved_ids).to contain_exactly(offender.nomis_offender_id)
        expect(CaseInformation.find_by(nomis_offender_id: offender.nomis_offender_id)).to be_present
      end
    end

    context 'when an offender has stint data, no local prison context, and prisoner-search resolves their prison' do
      let(:offender) { create(:offender) }

      before do
        create(:case_information, offender:)
        stub_summaries_for(
          [offender.nomis_offender_id],
          {
            offender.nomis_offender_id => offender_summary(prison_id: 'OUT', last_prison_id: prison.code)
          }
        )
      end

      it 'uses the resolved prison to verify release and clean up' do
        described_class.new(dry_run: false, prison_codes: [prison.code], batch_size: 1).call

        expect(HmppsApi::PrisonApi::OffenderApi).to have_received(:offender_summaries_for)
          .with([offender.nomis_offender_id].to_set, cache: false).at_least(:once)
        expect(CaseInformation.find_by(nomis_offender_id: offender.nomis_offender_id)).to be_nil
      end
    end

    context 'when an offender has stint data and prisoner-search resolves them to a non-target prison' do
      let(:offender) { create(:offender) }

      before do
        create(:case_information, offender:)
        stub_summaries_for(
          [offender.nomis_offender_id],
          {
            offender.nomis_offender_id => offender_summary(prison_id: 'MDI', legal_status: 'SENTENCED')
          }
        )
      end

      it 'keeps them unresolved for this targeted run and does not attempt release checks' do
        result = described_class.new(dry_run: false, prison_codes: [prison.code], batch_size: 1).call

        expect(result.released_ids).to be_empty
        expect(result.unresolved_ids).to contain_exactly(offender.nomis_offender_id)
      end
    end
  end
end
