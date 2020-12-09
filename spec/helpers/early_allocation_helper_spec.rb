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

  describe '#early_allocation_long_outcome' do
    context 'when eligible and unsent' do
      let(:early_allocation) { build(:early_allocation, :eligible, :unsent) }

      it 'works' do
        expect(helper.early_allocation_long_outcome(early_allocation)).to eq('Eligible - assessment not sent to the community probation team')
      end
    end

    context 'when eligible and sent' do
      let(:early_allocation) { build(:early_allocation, :eligible) }

      it 'works' do
        expect(helper.early_allocation_long_outcome(early_allocation)).to eq('Eligible - the community probation team will take responsibility for this case early')
      end
    end

    context 'when not eligible' do
      let(:early_allocation) { build(:early_allocation, :ineligible) }

      it 'works' do
        expect(helper.early_allocation_long_outcome(early_allocation)).to eq('Not eligible')
      end
    end

    context 'when discretionary - not sent' do
      let(:early_allocation) { build(:early_allocation, :discretionary, :unsent) }

      it 'works' do
        expect(helper.early_allocation_long_outcome(early_allocation)).to eq('Discretionary - assessment not sent to the community probation team')
      end
    end

    context 'when discretionary - sent' do
      let(:early_allocation) { build(:early_allocation, :discretionary) }

      it 'works' do
        expect(helper.early_allocation_long_outcome(early_allocation)).to eq('Discretionary - the community probation team will make a decision')
      end
    end

    context 'when discretionary - accepted' do
      let(:early_allocation) { build(:early_allocation, :discretionary, community_decision: true) }

      it 'works' do
        expect(helper.early_allocation_long_outcome(early_allocation)).to eq('Eligible - the community probation team will take responsibility for this case early')
      end
    end

    context 'when discretionary - rejected' do
      let(:early_allocation) { build(:early_allocation, :discretionary, community_decision: false) }

      it 'works' do
        expect(helper.early_allocation_long_outcome(early_allocation)).to eq('Not eligible')
      end
    end
  end
end
