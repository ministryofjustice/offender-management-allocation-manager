# frozen_string_literal: true

RSpec.describe ProbationCaseMerge do
  describe '.canonical_crn_for' do
    it 'returns the CRN unchanged when it has never been merged' do
      expect(described_class.canonical_crn_for('X12345')).to eq('X12345')
    end

    it 'returns the canonical CRN at the end of a merge chain' do
      create(:probation_case_merge, old_crn: 'X12345', new_crn: 'X54321')
      create(:probation_case_merge, old_crn: 'X54321', new_crn: 'X99999')

      expect(described_class.canonical_crn_for('X12345')).to eq('X99999')
    end

    it 'ignores inactive merge rows' do
      create(:probation_case_merge, :inactive, old_crn: 'X12345', new_crn: 'X54321')

      expect(described_class.canonical_crn_for('X12345')).to eq('X12345')
    end
  end

  describe 'validations' do
    it 'is invalid without old_crn' do
      expect(build(:probation_case_merge, old_crn: nil)).not_to be_valid
    end

    it 'is invalid without new_crn' do
      expect(build(:probation_case_merge, new_crn: nil)).not_to be_valid
    end

    it 'is invalid if old_crn is not unique among active merges' do
      create(:probation_case_merge, old_crn: 'X12345', new_crn: 'X54321')
      duplicate = build(:probation_case_merge, old_crn: 'X12345', new_crn: 'X99999')

      expect(duplicate).not_to be_valid
    end

    it 'allows an inactive row to reuse old_crn' do
      create(:probation_case_merge, old_crn: 'X12345', new_crn: 'X54321')
      inactive = build(:probation_case_merge, :inactive, old_crn: 'X12345', new_crn: 'X99999')

      expect(inactive).to be_valid
    end

    it 'is invalid when it would create a cycle' do
      create(:probation_case_merge, old_crn: 'X12345', new_crn: 'X54321')
      cyclic = build(:probation_case_merge, old_crn: 'X54321', new_crn: 'X12345')

      expect(cyclic).not_to be_valid
      expect(cyclic.errors[:new_crn]).to include('would create a merge cycle')
    end

    describe '.record_merge!' do
      it 'returns existing active merge for same pair' do
        existing = create(:probation_case_merge, old_crn: 'X12345', new_crn: 'X54321')

        merge = described_class.record_merge!(old_crn: 'X12345', new_crn: 'X54321')
        expect(merge).to eq(existing)
      end

      it 'supersedes current active merge and creates a new one for a different target CRN' do
        existing = create(:probation_case_merge, old_crn: 'X12345', new_crn: 'X54321')

        new_merge = described_class.record_merge!(old_crn: 'X12345', new_crn: 'X99999')
        existing.reload

        aggregate_failures do
          expect(existing.active).to be(false)
          expect(existing.superseded_at).to be_present
          expect(new_merge.active).to be(true)
          expect(new_merge.new_crn).to eq('X99999')
        end
      end
    end

    describe '.record_unmerge!' do
      it 'deactivates the active merge row when it exists' do
        merge = create(:probation_case_merge, old_crn: 'X12345', new_crn: 'X54321')

        result = described_class.record_unmerge!(old_crn: 'X12345', new_crn: 'X54321')
        merge.reload

        aggregate_failures do
          expect(result).to be(true)
          expect(merge.active).to be(false)
          expect(merge.superseded_at).to be_present
        end
      end

      it 'returns false when there is no matching active merge' do
        expect(described_class.record_unmerge!(old_crn: 'X12345', new_crn: 'X54321')).to be(false)
      end
    end
  end

  describe 'auditing' do
    it 'publishes an AuditEvent on create' do
      merge = create(:probation_case_merge, old_crn: 'X12345', new_crn: 'X54321')

      audit = AuditEvent
                .where('ARRAY[?]::text[] <@ tags', %w[record probation_case_merge created])
                .order(:created_at)
                .last

      aggregate_failures do
        expect(audit).to be_present
        expect(audit.tags).to include('record', 'probation_case_merge', 'created')
        expect(audit.data['canonical_crn']).to eq(merge.new_crn)
        expect(audit.data['after']).to include('old_crn' => merge.old_crn, 'new_crn' => merge.new_crn)
      end
    end
  end
end
