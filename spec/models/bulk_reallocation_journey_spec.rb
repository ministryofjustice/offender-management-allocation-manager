# frozen_string_literal: true

require 'rails_helper'

RSpec.describe BulkReallocationJourney do
  subject(:journey) { described_class.new(data) }

  let(:data) do
    {
      source_pom_id: 100,
      target_pom_id: 200,
      selected_offender_ids: %w[A1111AA B2222BB C3333CC],
      override_offender_ids: %w[B2222BB C3333CC],
      overrides: {},
    }
  end

  describe '#matches?' do
    it 'returns true when both POM IDs match' do
      expect(journey.matches?(100, 200)).to be true
    end

    it 'accepts string IDs' do
      expect(journey.matches?('100', '200')).to be true
    end

    it 'returns false when source differs' do
      expect(journey.matches?(999, 200)).to be false
    end

    it 'returns false when target differs' do
      expect(journey.matches?(100, 999)).to be false
    end

    it 'returns false when initialised with nil data' do
      expect(described_class.new(nil).matches?(100, 200)).to be false
    end
  end

  describe 'offender ID sets' do
    it 'returns the selected offender IDs' do
      expect(journey.selected_offender_ids).to eq %w[A1111AA B2222BB C3333CC]
    end

    it 'returns the override offender IDs' do
      expect(journey.override_offender_ids).to eq %w[B2222BB C3333CC]
    end

    it 'returns pending override IDs (active overrides without stored overrides)' do
      expect(journey.pending_override_offender_ids).to eq %w[B2222BB C3333CC]
    end

    it 'identifies missing selected offender IDs' do
      expect(journey.missing_selected_offender_ids(%w[A1111AA C3333CC D4444DD])).to eq(%w[B2222BB])
    end

    it 'is stale when a selected offender is no longer available' do
      expect(journey.stale?(%w[A1111AA C3333CC])).to be true
    end
  end

  describe '#exclude_offender!' do
    it 'removes the offender from selected and override lists' do
      journey.exclude_offender!('B2222BB')

      expect(journey.selected_offender_ids).to eq %w[A1111AA C3333CC]
      expect(journey.override_offender_ids).to eq %w[C3333CC]
    end

    it 'removes any stored override for the excluded offender' do
      journey.store_override_attributes!('B2222BB', { override_reasons: ['other'], more_detail: 'reason' })
      journey.exclude_offender!('B2222BB')

      expect(journey.overrides).not_to have_key('B2222BB')
    end

    it 'is idempotent' do
      2.times { journey.exclude_offender!('B2222BB') }
      expect(journey.selected_offender_ids).to eq %w[A1111AA C3333CC]
      expect(journey.override_offender_ids).to eq %w[C3333CC]
    end
  end

  describe '#store_override_attributes!' do
    let(:override_attributes) { { override_reasons: ['suitability'], suitability_detail: 'Fits well' } }

    it 'persists the override for the given offender' do
      journey.store_override_attributes!('B2222BB', override_attributes)

      expect(journey.overrides['B2222BB']).to eq('override_reasons' => ['suitability'], 'suitability_detail' => 'Fits well')
    end

    it 'removes the offender from pending overrides' do
      journey.store_override_attributes!('B2222BB', override_attributes)

      expect(journey.pending_override_offender_ids).to eq %w[C3333CC]
    end
  end

  describe '#override_for' do
    it 'returns an empty hash when no override exists' do
      expect(journey.override_for('A1111AA')).to eq({})
    end

    it 'returns the stored override when present' do
      journey.store_override_attributes!('B2222BB', { override_reasons: ['other'] })

      expect(journey.override_for('B2222BB')).to include('override_reasons' => ['other'])
    end
  end

  describe '#to_h' do
    it 'returns a Hash suitable for session storage' do
      result = journey.to_h
      expect(result).to be_a(Hash)
      expect(result['source_pom_id']).to eq 100
    end
  end
end
