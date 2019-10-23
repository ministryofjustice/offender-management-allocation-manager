# frozen_string_literal: true

require 'rails_helper'

RSpec.describe EarlyAllocationHelper, type: :helper do
  it 'says not assessed for nil' do
    expect(helper.early_allocation_status(nil)).to eq('Not assessed')
  end

  context 'when eligible' do
    subject { build(:early_allocation) }

    it 'says eligible' do
      expect(helper.early_allocation_status(subject)).to eq('Eligible')
    end
  end

  context 'when ineligible' do
    subject { build(:early_allocation, :ineligible) }

    it 'says ineligible' do
      expect(helper.early_allocation_status(subject)).to eq('Not eligible')
    end
  end

  context 'when deferred' do
    subject { build(:early_allocation, :discretionary) }

    it 'says pending when deferred to community' do
      expect(helper.early_allocation_status(subject)).to eq('Waiting for community decision')
    end
  end

  context 'when deferred but community said yes' do
    subject { build(:early_allocation, :discretionary, community_decision: true) }

    it 'says eligible' do
      expect(helper.early_allocation_status(subject)).to eq('Eligible')
    end
  end

  context 'when deferred but community said no' do
    subject { build(:early_allocation, :discretionary, community_decision: false) }

    it 'says ineligible' do
      expect(helper.early_allocation_status(subject)).to eq('Not eligible')
    end
  end
end
