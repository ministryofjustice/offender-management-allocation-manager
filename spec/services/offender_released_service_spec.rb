# frozen_string_literal: true

require 'rails_helper'

RSpec.describe OffenderReleasedService do
  before do
    stub_pom(
      build(:pom, staffId: 485_926, firstName: 'MOIC', lastName: 'POM', primaryEmail: 'test@example.com')
    )
    stub_offender(
      build(:nomis_offender, prisonerNumber: offender.nomis_offender_id, prisonId: 'OUT', firstName: 'John', lastName: 'Doe')
    )
  end

  let!(:prison) { Prison.find_by(code: 'LEI') || create(:prison, code: 'LEI') }
  let(:offender) { create(:offender, nomis_offender_id: 'G7266VD') }

  describe '.release_offender' do
    context 'with full stint data and an active allocation' do
      let!(:case_info) { create(:case_information, offender:) }
      let!(:allocation) { create(:allocation_history, prison: 'LEI', nomis_offender_id: offender.nomis_offender_id) }
      let!(:calculated_handover_date) { create(:calculated_handover_date, offender:) }
      let!(:handover_progress_checklist) { create(:handover_progress_checklist, offender:) }
      let!(:responsibility) { create(:responsibility, offender:) }
      let!(:omic_eligibility) { create(:omic_eligibility, nomis_offender_id: offender.nomis_offender_id) }

      it 'deallocates the offender and destroys all stint data' do
        described_class.release_offender(offender.nomis_offender_id, prison_code: 'LEI')

        expect(allocation.reload.active?).to be false
        expect(allocation.event_trigger).to eq 'offender_released'
        expect(CaseInformation.find_by(nomis_offender_id: offender.nomis_offender_id)).to be_nil
        expect(CalculatedHandoverDate.find_by(nomis_offender_id: offender.nomis_offender_id)).to be_nil
        expect(HandoverProgressChecklist.find_by(nomis_offender_id: offender.nomis_offender_id)).to be_nil
        expect(Responsibility.find_by(nomis_offender_id: offender.nomis_offender_id)).to be_nil
        expect(OmicEligibility.find_by(nomis_offender_id: offender.nomis_offender_id)).to be_nil
      end

      it 'inactivates complexity for womens prisons' do
        expect(HmppsApi::ComplexityApi).to receive(:inactivate).with(offender.nomis_offender_id)
        described_class.release_offender(offender.nomis_offender_id, prison_code: 'AGI')
      end

      it 'does not inactivate complexity for mens prisons' do
        expect(HmppsApi::ComplexityApi).not_to receive(:inactivate)
        described_class.release_offender(offender.nomis_offender_id, prison_code: 'LEI')
      end
    end

    context 'when there is no active allocation' do
      let!(:case_info) { create(:case_information, offender:) }

      it 'still destroys stint data without error' do
        described_class.release_offender(offender.nomis_offender_id)

        expect(CaseInformation.find_by(nomis_offender_id: offender.nomis_offender_id)).to be_nil
      end
    end

    context 'when called without prison_code (reconciliation scenario)' do
      let!(:case_info) { create(:case_information, offender:) }
      let!(:allocation) { create(:allocation_history, prison: 'LEI', nomis_offender_id: offender.nomis_offender_id) }

      it 'deallocates and destroys stint data without inactivating complexity' do
        expect(HmppsApi::ComplexityApi).not_to receive(:inactivate)

        described_class.release_offender(offender.nomis_offender_id)

        expect(allocation.reload.active?).to be false
        expect(CaseInformation.find_by(nomis_offender_id: offender.nomis_offender_id)).to be_nil
      end

      it 'can skip deallocation email and still complete cleanup when offender lookup is missing' do
        allow(HmppsApi::PrisonApi::OffenderApi).to receive(:get_offender).and_return(nil)
        expect(PomMailer).not_to receive(:with)

        described_class.release_offender(offender.nomis_offender_id, send_email: false)

        expect(allocation.reload.active?).to be false
        expect(CaseInformation.find_by(nomis_offender_id: offender.nomis_offender_id)).to be_nil
      end
    end

    context 'when all local release state has already been removed' do
      it 'skips duplicate processing, including complexity inactivation' do
        expect(HmppsApi::ComplexityApi).not_to receive(:inactivate)

        expect { described_class.release_offender(offender.nomis_offender_id, prison_code: 'AGI') }
          .not_to raise_error
      end
    end

    context 'when only some local release state remains' do
      let!(:omic_eligibility) { create(:omic_eligibility, nomis_offender_id: offender.nomis_offender_id, prison: 'AGI') }

      it 'continues cleanup and inactivates complexity for womens prisons' do
        expect(HmppsApi::ComplexityApi).to receive(:inactivate).with(offender.nomis_offender_id)

        described_class.release_offender(offender.nomis_offender_id, prison_code: 'AGI')

        expect(OmicEligibility.find_by(nomis_offender_id: offender.nomis_offender_id)).to be_nil
      end
    end

    context 'when a destroy fails' do
      let!(:case_info) { create(:case_information, offender:) }
      let!(:calculated_handover_date) { create(:calculated_handover_date, offender:) }

      it 'continues processing remaining models' do
        allow_any_instance_of(CaseInformation).to receive(:destroy!).and_raise(ActiveRecord::StatementInvalid, 'boom')

        expect { described_class.release_offender(offender.nomis_offender_id) }.not_to raise_error

        # CaseInformation destroy failed, but it should still be attempted
        expect(CaseInformation.find_by(nomis_offender_id: offender.nomis_offender_id)).to be_present
        # CalculatedHandoverDate should still be destroyed
        expect(CalculatedHandoverDate.find_by(nomis_offender_id: offender.nomis_offender_id)).to be_nil
      end
    end
  end

  describe '.destroy_stint_data' do
    let!(:case_info) { create(:case_information, offender:) }

    it 'is publicly accessible for targeted cleanup' do
      described_class.destroy_stint_data(offender.nomis_offender_id)

      expect(CaseInformation.find_by(nomis_offender_id: offender.nomis_offender_id)).to be_nil
    end
  end
end
