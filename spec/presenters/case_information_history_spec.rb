require 'rails_helper'

RSpec.describe CaseInformationHistory do
  let(:event) { 'update' }
  let(:version) { PaperTrail::Version.new(event:) }
  let(:presenter) { described_class.new(version) }
  let(:expected_partial_path) { 'case_history/case_information/update' }

  it_behaves_like 'a paper trail timeline presenter'

  describe '.timeline_entries_for' do
    let(:nomis_offender_id) { 'A1234BC' }
    let(:create_version) { PaperTrail::Version.new(event: 'create', object_changes: YAML.dump('tier' => [nil, 'A'])) }
    let(:tracked_version) { PaperTrail::Version.new(event: 'update', object_changes: YAML.dump('tier' => ['A', 'B'])) }
    let(:tracked_nil_version) { PaperTrail::Version.new(event: 'update', object_changes: YAML.dump('enhanced_resourcing' => [false, nil])) }
    let(:destroy_version) { PaperTrail::Version.new(event: 'destroy') }
    let(:hidden_version) { PaperTrail::Version.new }

    it 'builds presenters for tracked create and update versions, including changes to nil, and filters out hidden entries' do
      allow(PaperTrail::Version).to receive(:where)
        .with(item_type: 'CaseInformation', nomis_offender_id: nomis_offender_id)
        .and_return([create_version, tracked_version, tracked_nil_version, destroy_version, hidden_version])

      entries = described_class.timeline_entries_for(nomis_offender_id)

      expect(entries.map(&:event)).to eq(%w[create update update])
    end
  end

  describe '#event' do
    it 'returns the PaperTrail event for updates even when manual_entry changes' do
      version = PaperTrail::Version.new(
        event: 'update',
        object_changes: YAML.dump('manual_entry' => [false, true], 'tier' => [nil, 'B'])
      )

      presenter = described_class.new(version)

      aggregate_failures do
        expect(presenter.event).to eq('update')
        expect(presenter.to_partial_path).to eq('case_history/case_information/update')
      end
    end

    it 'keeps create versions mapped to the create partial' do
      presenter = described_class.new(PaperTrail::Version.new(event: 'create'))

      aggregate_failures do
        expect(presenter.event).to eq('create')
        expect(presenter.to_partial_path).to eq('case_history/case_information/create')
      end
    end
  end

  describe '#change_details' do
    it 'returns an empty list when the version has no tracked CaseInformation changes' do
      expect(described_class.new(PaperTrail::Version.new).change_details).to eq([])
    end

    it 'returns the tracked details in the timeline order' do
      version = PaperTrail::Version.new(
        object_changes: YAML.dump(
          'tier' => ['A', 'C'],
          'rosh_level' => ['HIGH', 'VERY_HIGH'],
          'enhanced_resourcing' => [false, true]
        )
      )

      details = described_class.new(version).change_details

      aggregate_failures do
        expect(details.map(&:label)).to eq(['Tier', 'ROSH', 'Resourcing'])
        expect(details.map(&:from_value)).to eq(['A', 'High', 'standard'])
        expect(details.map(&:to_value)).to eq(['C', 'Very high', 'enhanced'])
      end
    end

    it 'does not include ROSH details when the rosh_level feature flag is disabled' do
      stub_feature_flag(:rosh_level, enabled: false)

      version = PaperTrail::Version.new(
        object_changes: YAML.dump(
          'tier' => ['A', 'C'],
          'rosh_level' => ['HIGH', 'VERY_HIGH'],
          'enhanced_resourcing' => [false, true]
        )
      )

      details = described_class.new(version).change_details

      aggregate_failures do
        expect(details.map(&:label)).to eq(['Tier', 'Resourcing'])
        expect(details.map(&:from_value)).to eq(['A', 'standard'])
        expect(details.map(&:to_value)).to eq(['C', 'enhanced'])
      end
    end

    it 'ignores non-timeline attributes from the PaperTrail changeset' do
      version = PaperTrail::Version.new(
        object_changes: YAML.dump(
          'manual_entry' => [false, true],
          'tier' => ['B', 'D']
        )
      )

      details = described_class.new(version).change_details

      aggregate_failures do
        expect(details.size).to eq(1)
        expect(details.first.label).to eq('Tier')
        expect(details.first.from_value).to eq('B')
        expect(details.first.to_value).to eq('D')
      end
    end

    it 'keeps tracked updates when the new value is nil' do
      version = PaperTrail::Version.new(
        event: 'update',
        object_changes: YAML.dump(
          'enhanced_resourcing' => [false, nil]
        )
      )

      details = described_class.new(version).change_details

      aggregate_failures do
        expect(details.size).to eq(1)
        expect(details.first.label).to eq('Resourcing')
        expect(details.first.from_value).to eq('standard')
        expect(details.first.to_value).to eq('(unset)')
      end
    end

    it 'returns no tracked details for destroy versions because the timeline uses generic copy' do
      version = PaperTrail::Version.new(
        event: 'destroy',
        object_changes: YAML.dump(
          'tier' => ['B', nil],
          'rosh_level' => ['LOW', nil],
          'enhanced_resourcing' => [false, nil]
        )
      )

      details = described_class.new(version).change_details

      expect(details).to eq([])
    end
  end
end
