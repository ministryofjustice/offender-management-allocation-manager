require 'rails_helper'

RSpec.describe EarlyAllocationDecision do
  describe '#created_at' do
    it 'uses the updated_at timestamp' do
      updated_at = Time.zone.local(2024, 1, 15, 10, 30, 0)
      early_allocation = build(:early_allocation, :discretionary_accepted, updated_at:)

      expect(described_class.new(early_allocation).created_at).to eq(updated_at)
    end
  end

  describe '#created_by_name' do
    it 'returns the updater full name' do
      early_allocation = build(:early_allocation, :discretionary_accepted, updated_by_firstname: 'Joe', updated_by_lastname: 'Bloggs')

      expect(described_class.new(early_allocation).created_by_name).to eq('Joe Bloggs')
    end
  end

  describe '#to_partial_path' do
    it 'uses the eligible decision partial when the community accepts the case' do
      early_allocation = build(:early_allocation, :discretionary_accepted)

      expect(described_class.new(early_allocation).to_partial_path).to eq('case_history/early_allocation/decision_eligible')
    end

    it 'uses the ineligible decision partial when the community declines the case' do
      early_allocation = build(:early_allocation, :discretionary_declined)

      expect(described_class.new(early_allocation).to_partial_path).to eq('case_history/early_allocation/decision_ineligible')
    end
  end
end
