# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PruneOrphanedCaseDataService do
  let!(:fresh_eligibility) { OmicEligibility.create!(nomis_offender_id: 'A0000AA', eligible: true, prison: 'LEI') }

  describe '#call' do
    context 'when an offender is in OmicEligibility' do
      it 'is never pruned, regardless of allocation state' do
        offender = create(:offender)
        create(:case_information, offender:)
        OmicEligibility.create!(nomis_offender_id: offender.nomis_offender_id, eligible: true, prison: 'LEI')

        result = described_class.new(dry_run: false).call

        expect(result.total_count).to eq(0)
        expect(CaseInformation.find_by(nomis_offender_id: offender.nomis_offender_id)).to be_present
      end
    end

    context 'when never allocated and older than min age' do
      let(:offender) { create(:offender) }

      before do
        create(:case_information, offender:, updated_at: 4.months.ago)
      end

      it 'is identified as a candidate' do
        result = described_class.new.call

        expect(result.never_allocated_ids).to include(offender.nomis_offender_id)
      end

      it 'does not delete in dry-run mode' do
        described_class.new(dry_run: true).call

        expect(CaseInformation.find_by(nomis_offender_id: offender.nomis_offender_id)).to be_present
      end

      it 'deletes stint data in process mode' do
        create(:calculated_handover_date, offender:)
        create(:responsibility, offender:)

        described_class.new(dry_run: false).call

        expect(CaseInformation.find_by(nomis_offender_id: offender.nomis_offender_id)).to be_nil
        expect(CalculatedHandoverDate.find_by(nomis_offender_id: offender.nomis_offender_id)).to be_nil
        expect(Responsibility.find_by(nomis_offender_id: offender.nomis_offender_id)).to be_nil
      end
    end

    context 'when never allocated but more recent than min age' do
      let(:offender) { create(:offender) }

      before do
        create(:case_information, offender:, updated_at: 1.month.ago)
      end

      it 'is not a candidate' do
        result = described_class.new.call

        expect(result.never_allocated_ids).not_to include(offender.nomis_offender_id)
        expect(CaseInformation.find_by(nomis_offender_id: offender.nomis_offender_id)).to be_present
      end
    end

    context 'when never allocated but min_age is configurable' do
      let(:offender) { create(:offender) }

      before do
        create(:case_information, offender:, updated_at: 2.months.ago)
      end

      it 'respects a custom min_age when set shorter' do
        result = described_class.new(never_allocated_min_age: 1.month).call

        expect(result.never_allocated_ids).to include(offender.nomis_offender_id)
      end
    end

    context 'when an allocation exists even if inactive' do
      let(:offender) { create(:offender) }

      before do
        create(:case_information, offender:, updated_at: 4.months.ago)
        create(:allocation_history, :transfer, nomis_offender_id: offender.nomis_offender_id, prison: 'LEI')
      end

      it 'is excluded from never-allocated' do
        result = described_class.new.call

        expect(result.never_allocated_ids).not_to include(offender.nomis_offender_id)
      end
    end

    context 'when allocation has offender_released trigger' do
      let(:offender) { create(:offender) }

      before do
        create(:case_information, offender:)
        create(:allocation_history, :release, nomis_offender_id: offender.nomis_offender_id, prison: 'LEI')
      end

      it 'is identified as a candidate' do
        result = described_class.new.call

        expect(result.released_allocation_ids).to include(offender.nomis_offender_id)
      end

      it 'does not delete in dry-run mode' do
        described_class.new(dry_run: true).call

        expect(CaseInformation.find_by(nomis_offender_id: offender.nomis_offender_id)).to be_present
      end

      it 'deletes stint data in process mode' do
        create(:calculated_handover_date, offender:)

        described_class.new(dry_run: false).call

        expect(CaseInformation.find_by(nomis_offender_id: offender.nomis_offender_id)).to be_nil
        expect(CalculatedHandoverDate.find_by(nomis_offender_id: offender.nomis_offender_id)).to be_nil
      end
    end

    context 'when allocation has a non-release trigger' do
      let(:offender) { create(:offender) }

      before do
        create(:case_information, offender:)
        create(:allocation_history, :primary, nomis_offender_id: offender.nomis_offender_id, prison: 'LEI')
      end

      it 'is not a candidate' do
        result = described_class.new.call

        expect(result.released_allocation_ids).not_to include(offender.nomis_offender_id)
        expect(CaseInformation.find_by(nomis_offender_id: offender.nomis_offender_id)).to be_present
      end
    end

    context 'when an offender appears in both queries' do
      let(:offender) { create(:offender) }

      before do
        create(:case_information, offender:, updated_at: 4.months.ago)
        create(:allocation_history, :release, nomis_offender_id: offender.nomis_offender_id, prison: 'LEI')
      end

      it 'counts them only once in total_count' do
        result = described_class.new.call

        expect(result.never_allocated_ids).not_to include(offender.nomis_offender_id)
        expect(result.released_allocation_ids).to include(offender.nomis_offender_id)
        expect(result.total_count).to eq(1)
      end
    end

    context 'when multiple candidates exist across queries' do
      let(:offender_never_alloc) { create(:offender) }
      let(:offender_released) { create(:offender) }
      let(:offender_still_active) { create(:offender) }

      before do
        create(:case_information, offender: offender_never_alloc, updated_at: 4.months.ago)
        create(:case_information, offender: offender_released)
        create(:case_information, offender: offender_still_active)
        create(:allocation_history, :release, nomis_offender_id: offender_released.nomis_offender_id, prison: 'LEI')
        create(:allocation_history, :primary, nomis_offender_id: offender_still_active.nomis_offender_id, prison: 'LEI')
      end

      it 'returns correct totals' do
        result = described_class.new.call

        expect(result.never_allocated_count).to eq(1)
        expect(result.released_allocation_count).to eq(1)
        expect(result.total_count).to eq(2)
      end

      it 'only deletes candidates in process mode' do
        described_class.new(dry_run: false).call

        expect(CaseInformation.find_by(nomis_offender_id: offender_never_alloc.nomis_offender_id)).to be_nil
        expect(CaseInformation.find_by(nomis_offender_id: offender_released.nomis_offender_id)).to be_nil
        expect(CaseInformation.find_by(nomis_offender_id: offender_still_active.nomis_offender_id)).to be_present
      end
    end
  end
end
