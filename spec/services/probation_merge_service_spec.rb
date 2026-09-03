# frozen_string_literal: true

RSpec.describe ProbationMergeService do
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
    it 'returns false when CRN has no local case information' do
      expect(described_class.locally_tracked?('X00000')).to be false
    end

    it 'returns true when CRN exists in case information' do
      expect(described_class.locally_tracked?(old_crn)).to be true
    end
  end

  describe '#process' do
    it 'records the merge in the database' do
      expect { service.process }.to change(ProbationCaseMerge, :count).by(1)
    end

    it 'stores the correct old and new CRNs as an active merge row' do
      service.process
      merge = ProbationCaseMerge.find_by!(old_crn:)
      aggregate_failures do
        expect(merge.new_crn).to eq(new_crn)
        expect(merge.active).to be(true)
      end
    end

    it 'migrates case information to canonical CRN when target is not present' do
      service.process

      expect(CaseInformation.find_by(crn: old_crn)).to be_nil
      expect(CaseInformation.find_by(crn: new_crn)).to eq(old_case_info.reload)
    end

    it 'logs migrate_record for case information reassignment' do
      service.process

      expect_logged_info(/event=migrate_record.*old_crn=#{old_crn}.*record=case_information.*canonical_crn=#{new_crn}/)
    end

    it 'creates a paper trail version that captures crn reassignment' do
      before_count = old_case_info.versions.count
      service.process

      expect(old_case_info.reload.versions.count).to eq(before_count + 1)
      changeset = YAML.unsafe_load(old_case_info.reload.versions.last.object_changes)
      expect(changeset['crn']).to eq([old_crn, new_crn])
    end

    it 'publishes a probation merge audit event when case information is migrated' do
      service.process

      audit = AuditEvent
                .where("ARRAY[?]::text[] <@ tags", %w[service probation_merge migrated case_information])
                .where(nomis_offender_id: old_offender.nomis_offender_id)
                .where("data ->> 'old_crn' = ?", old_crn)
                .where("data ->> 'canonical_crn' = ?", new_crn)
                .last
      expect(audit).to be_present
    end

    context 'when canonical CRN already has case information' do
      let!(:new_case_info) { create(:case_information, offender: new_offender, crn: new_crn, tier: 'A') }

      it 'does not overwrite the canonical record and keeps old one unchanged' do
        service.process

        aggregate_failures do
          expect(new_case_info.reload.tier).to eq('A')
          expect(old_case_info.reload.crn).to eq(old_crn)
        end
      end

      it 'logs migrate_record_already_present' do
        service.process
        expect_logged_info(/event=migrate_record_already_present.*old_crn=#{old_crn}.*record=case_information.*canonical_crn=#{new_crn}/)
      end
    end

    context 'when the merge is part of a chain' do
      let!(:existing_merge) { create(:probation_case_merge, old_crn: new_crn, new_crn: 'X99999') }

      it 'migrates to the end-of-chain canonical CRN' do
        service.process
        expect(old_case_info.reload.crn).to eq('X99999')
      end
    end

    it 'is idempotent when processed more than once' do
      service.process
      expect { service.process }.not_to change(ProbationCaseMerge, :count)
    end

    it 'supersedes old active merge when re-merged to a different target CRN' do
      service.process

      described_class.new(old_crn:, new_crn: 'X99999').process
      old_merge = ProbationCaseMerge.find_by!(old_crn:, new_crn:)
      new_merge = ProbationCaseMerge.find_by!(old_crn:, new_crn: 'X99999')

      aggregate_failures do
        expect(old_merge.active).to be(false)
        expect(old_merge.superseded_at).to be_present
        expect(new_merge.active).to be(true)
      end
    end

    context 'when probation_merges feature flag is disabled' do
      before do
        stub_feature_flag(:probation_merges, enabled: false)
      end

      it 'records merge mapping but skips case information reassignment' do
        expect { service.process }.to change(ProbationCaseMerge, :count).by(1)
        expect(old_case_info.reload.crn).to eq(old_crn)
        expect(CaseInformation.find_by(crn: new_crn)).to be_nil
      end
    end
  end
end
