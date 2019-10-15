# frozen_string_literal: true

require 'rails_helper'

RSpec.describe EarlyAllocation, type: :model do
  it 'validates 2nd level booleans when first ones present' do
    expect(build(:early_allocation)).to be_valid
  end

  it 'validates stage2 fields when stage1 is complete' do
    expect(build(:early_allocation, stage2_validation: true)).not_to be_valid

    expect(build(:early_allocation, :stage2)).to be_valid
  end

  it 'validates presence of 24 month release when extremism seperation is true' do
    expect(build(:early_allocation, :stage2, extremism_separation: true)).not_to be_valid

    expect(build(:early_allocation, :stage2, extremism_separation: true, due_for_release_in_less_than_24months: false)).to be_valid
    expect(build(:early_allocation, :stage2, extremism_separation: true, due_for_release_in_less_than_24months: true)).to be_valid
  end

  it 'validates stage2 attributes' do
    expect(build(:early_allocation, :stage2)).to be_valid
  end

  describe '#eligible?' do
    it 'is not eligible (actually unsure) if all of the stage1 booleans are false' do
      expect(build(:early_allocation, :discretionary).eligible?).to eq(false)
    end

    it 'is eligible if any stage1 boolean is true' do
      expect(build(:early_allocation, convicted_under_terrorisom_act_2000: true).eligible?).to eq(true)
    end
  end

  describe '#ineligible?' do
    context 'when eligible (default)' do
      subject { build(:early_allocation).ineligible? }

      it 'is not ineligible (actually unsure) if all of the stage1 booleans are false' do
        expect(subject).to eq(false)
      end
    end

    context 'when all 10 booleans are false' do
      subject { build(:early_allocation, :ineligible).ineligible? }

      it 'is ineligible' do
        expect(subject).to eq(true)
      end
    end

    context 'with extremism_seperation true' do
      subject {
        build(:early_allocation, :ineligible,
              extremism_separation: true,
              due_for_release_in_less_than_24months: release_24).ineligible?
      }

      context 'when > 24 months' do
        let(:release_24) { false }

        it 'is not ineligible' do
          expect(subject).to eq(true)
        end
      end

      context 'when < 24 months' do
        let(:release_24) { true }

        it 'is ineligible' do
          expect(subject).to eq(false)
        end
      end
    end
  end
end
