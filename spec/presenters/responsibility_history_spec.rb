require 'rails_helper'

RSpec.describe ResponsibilityHistory do
  let(:event) { 'destroy' }
  let(:version) { PaperTrail::Version.new(event:) }
  let(:presenter) { described_class.new(version) }
  let(:expected_partial_path) { 'case_history/responsibility/destroy' }

  it_behaves_like 'a paper trail timeline presenter'

  describe '#reason_detail' do
    it 'returns nil when the version has no stored reason changes' do
      expect(described_class.new(PaperTrail::Version.new).reason_detail).to be_nil
    end

    it 'returns nil when the stored reason has no matching locale label' do
      version = PaperTrail::Version.new(
        object_changes: YAML.dump('reason' => [nil, 'unknown_reason'])
      )

      expect(described_class.new(version).reason_detail).to be_nil
    end

    it 'returns a readable label for the stored override reason' do
      version = PaperTrail::Version.new(
        object_changes: YAML.dump('reason' => [nil, 'prisoner_has_been_recalled'])
      )

      expect(described_class.new(version).reason_detail).to eq('Prisoner has been recalled')
    end

    it 'handles a stored enum integer value from PaperTrail' do
      version = PaperTrail::Version.new(
        object_changes: YAML.dump(
          'reason' => [nil, Responsibility::OTHER_REASON],
          'reason_text' => [nil, 'Because of local circumstances']
        )
      )

      expect(described_class.new(version).reason_detail).to eq('Other – Because of local circumstances')
    end

    it 'includes the free-text detail for the Other reason' do
      version = PaperTrail::Version.new(
        object_changes: YAML.dump(
          'reason' => [nil, 'other_reason'],
          'reason_text' => [nil, 'Because of local circumstances']
        )
      )

      expect(described_class.new(version).reason_detail).to eq('Other – Because of local circumstances')
    end
  end
end
