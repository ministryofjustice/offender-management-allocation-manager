# frozen_string_literal: true

RSpec.describe ProbationUnmergeService do
  subject(:service) do
    described_class.new(
      old_crn:,
      new_crn:
    )
  end

  let(:old_crn) { 'X12345' }
  let(:new_crn) { 'X54321' }
  let!(:old_offender) { create(:offender, nomis_offender_id: 'A1234BC') }
  let!(:new_offender) { create(:offender, nomis_offender_id: 'A9876ZY') }
  let!(:old_case_info) { create(:case_information, offender: old_offender, crn: old_crn, tier: 'B') }

  before do
    allow(Rails.logger).to receive(:info)
    stub_feature_flag(:probation_merges, enabled: true)
  end

  def expect_logged_info(pattern)
    expect(Rails.logger).to have_received(:info).with(a_string_matching(pattern))
  end

  describe '.locally_tracked?' do
    it 'returns true when there is a matching active merge row' do
      create(:probation_case_merge, old_crn:, new_crn:)

      expect(described_class.locally_tracked?(old_crn:, new_crn:)).to be(true)
    end

    it 'returns false when the matching merge row is inactive' do
      create(:probation_case_merge, :inactive, old_crn:, new_crn:)

      expect(described_class.locally_tracked?(old_crn:, new_crn:)).to be(false)
    end
  end

  describe '#process' do
    before do
      create(:probation_case_merge, old_crn:, new_crn:)
    end

    it 'deactivates a matching active merge row' do
      service.process

      merge = ProbationCaseMerge.find_by!(old_crn:, new_crn:)
      aggregate_failures do
        expect(merge.active).to be(false)
        expect(merge.superseded_at).to be_present
      end
    end

    it 'logs unmerge completion' do
      service.process

      expect_logged_info(/event=record_unmerge.*old_crn=#{old_crn}.*new_crn=#{new_crn}/)
    end

    it 'logs noop when no active merge row matches' do
      service.process
      service.process

      expect_logged_info(/event=record_unmerge_noop.*old_crn=#{old_crn}.*new_crn=#{new_crn}/)
    end

    context 'when old CRN case information already exists' do
      let!(:new_case_info) { create(:case_information, offender: new_offender, crn: new_crn, tier: 'A') }

      it 'keeps records unchanged and logs already present' do
        service.process

        aggregate_failures do
          expect(old_case_info.reload.crn).to eq(old_crn)
          expect(new_case_info.reload.crn).to eq(new_crn)
          expect_logged_info(/event=unmerge_case_information_already_present.*old_crn=#{old_crn}.*new_crn=#{new_crn}/)
        end
      end
    end

    context 'when old CRN case information is missing and new CRN exists' do
      before do
        old_case_info.update!(crn: new_crn)
      end

      it 'restores CRN back to old on the existing case information record' do
        service.process

        aggregate_failures do
          expect(old_case_info.reload.crn).to eq(old_crn)
          expect(CaseInformation.find_by(crn: new_crn)).to be_nil
          expect_logged_info(/event=unmerge_case_information_restored.*old_crn=#{old_crn}.*new_crn=#{new_crn}/)
        end
      end

      it 'publishes a probation unmerge audit event' do
        service.process

        audit = AuditEvent
                  .where("ARRAY[?]::text[] <@ tags", %w[service probation_merge unmerged case_information])
                  .where(nomis_offender_id: old_offender.nomis_offender_id)
                  .where("data ->> 'old_crn' = ?", old_crn)
                  .where("data ->> 'new_crn' = ?", new_crn)
                  .last

        expect(audit).to be_present
      end
    end

    context 'when both old and new CRN case information are missing' do
      before do
        old_case_info.destroy!
      end

      it 'logs source missing and does not recreate data' do
        service.process

        aggregate_failures do
          expect(CaseInformation.find_by(crn: old_crn)).to be_nil
          expect(CaseInformation.find_by(crn: new_crn)).to be_nil
          expect_logged_info(/event=unmerge_case_information_source_missing.*old_crn=#{old_crn}.*new_crn=#{new_crn}/)
        end
      end
    end

    context 'when probation_merges feature flag is disabled' do
      before do
        stub_feature_flag(:probation_merges, enabled: false)
        old_case_info.update!(crn: new_crn)
      end

      it 'deactivates merge mapping but skips case information restoration' do
        service.process

        merge = ProbationCaseMerge.find_by!(old_crn:, new_crn:)
        aggregate_failures do
          expect(merge.active).to be(false)
          expect(old_case_info.reload.crn).to eq(new_crn)
          expect(CaseInformation.find_by(crn: old_crn)).to be_nil
        end
      end
    end
  end
end
