require 'rails_helper'

RSpec.describe Timeline::EarlyAllocationHistory do
  describe '#created_by_name' do
    it 'returns the creator full name' do
      early_allocation = build(:early_allocation, created_by_firstname: 'Joe', created_by_lastname: 'Bloggs')

      expect(described_class.new(early_allocation).created_by_name).to eq('Joe Bloggs')
    end
  end

  describe '#to_partial_path' do
    it 'uses the eligible partial within the referral window' do
      early_allocation = build(:early_allocation)

      expect(described_class.new(early_allocation).to_partial_path).to eq('case_history/early_allocation/eligible')
    end

    it 'uses the discretionary partial within the referral window when a community decision exists' do
      early_allocation = build(:early_allocation, :discretionary_accepted)

      expect(described_class.new(early_allocation).to_partial_path).to eq('case_history/early_allocation/discretionary')
    end

    it 'uses the unsent discretionary partial outside the referral window' do
      early_allocation = build(:early_allocation, :pre_window, :discretionary)

      expect(described_class.new(early_allocation).to_partial_path).to eq('case_history/early_allocation/unsent_discretionary')
    end
  end
end
