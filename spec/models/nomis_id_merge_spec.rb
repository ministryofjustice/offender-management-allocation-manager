# frozen_string_literal: true

RSpec.describe NomisIdMerge do
  describe '.canonical_id_for' do
    context 'when the ID has never been merged' do
      it 'returns the ID unchanged' do
        expect(described_class.canonical_id_for('A1234BC')).to eq('A1234BC')
      end
    end

    context 'when the ID has been merged once' do
      before { create(:nomis_id_merge, old_nomis_id: 'A1234BC', new_nomis_id: 'Z9876XY') }

      it 'returns the successor ID' do
        expect(described_class.canonical_id_for('A1234BC')).to eq('Z9876XY')
      end

      it 'returns the successor unchanged when it has not been further merged' do
        expect(described_class.canonical_id_for('Z9876XY')).to eq('Z9876XY')
      end
    end

    context 'when the ID has been merged in a chain' do
      before do
        create(:nomis_id_merge, old_nomis_id: 'A1234BC', new_nomis_id: 'Z9876XY')
        create(:nomis_id_merge, old_nomis_id: 'Z9876XY', new_nomis_id: 'Q1111ZZ')
      end

      it 'resolves to the end of the chain' do
        expect(described_class.canonical_id_for('A1234BC')).to eq('Q1111ZZ')
      end

      it 'resolves an intermediate ID to the final canonical ID' do
        expect(described_class.canonical_id_for('Z9876XY')).to eq('Q1111ZZ')
      end

      it 'returns the final ID unchanged' do
        expect(described_class.canonical_id_for('Q1111ZZ')).to eq('Q1111ZZ')
      end
    end

    context 'when there is a cycle in the merge chain (data integrity guard)' do
      before do
        create(:nomis_id_merge, old_nomis_id: 'A1234BC', new_nomis_id: 'Z9876XY')
        create(:nomis_id_merge, old_nomis_id: 'Z9876XY', new_nomis_id: 'A1234BC')
      end

      it 'does not loop infinitely and returns a result' do
        result = described_class.canonical_id_for('A1234BC')
        expect(result).to be_in(['A1234BC', 'Z9876XY'])
      end
    end
  end

  describe 'validations' do
    it 'is invalid without old_nomis_id' do
      expect(build(:nomis_id_merge, old_nomis_id: nil)).not_to be_valid
    end

    it 'is invalid without new_nomis_id' do
      expect(build(:nomis_id_merge, new_nomis_id: nil)).not_to be_valid
    end

    it 'is invalid if old_nomis_id is not unique' do
      create(:nomis_id_merge, old_nomis_id: 'A1234BC', new_nomis_id: 'Z9876XY')
      duplicate = build(:nomis_id_merge, old_nomis_id: 'A1234BC', new_nomis_id: 'Q1111ZZ')

      expect(duplicate).not_to be_valid
    end
  end

  describe 'auditing' do
    it 'publishes an AuditEvent on create' do
      merge = create(:nomis_id_merge, old_nomis_id: 'A1234BC', new_nomis_id: 'Z9876XY')

      audit = AuditEvent
                .where('ARRAY[?]::text[] <@ tags', %w[record nomis_id_merge created])
                .order(:created_at)
                .last

      aggregate_failures do
        expect(audit).to be_present
        expect(audit.tags).to include('record', 'nomis_id_merge', 'created')
        expect(audit.nomis_offender_id).to eq(merge.old_nomis_id)
        expect(audit.data['canonical_id']).to eq(merge.new_nomis_id)
        expect(audit.data['after']).to include('old_nomis_id' => merge.old_nomis_id, 'new_nomis_id' => merge.new_nomis_id)
      end
    end
  end
end
