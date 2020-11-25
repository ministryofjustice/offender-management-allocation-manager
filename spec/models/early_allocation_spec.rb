# frozen_string_literal: true

require 'rails_helper'

RSpec.describe EarlyAllocation, type: :model do
  it 'validates 2nd level booleans when first ones present' do
    expect(build(:early_allocation)).to be_valid
  end

  context 'when oasys date more than 2 years adrift' do
    let(:ea) { build(:early_allocation, oasys_risk_assessment_date: Time.zone.today - 3.years) }

    it 'validates' do
      expect(ea).not_to be_valid
      expect(ea.errors.full_messages_for(:oasys_risk_assessment_date)).to eq(['This date must be in the last 3 months'])
    end
  end

  context 'when in the future' do
    let(:ea) { build(:early_allocation, oasys_risk_assessment_date: Time.zone.today + 3.years) }

    it 'validates' do
      expect(ea).not_to be_valid
      expect(ea.errors.full_messages_for(:oasys_risk_assessment_date)).to eq(['This must not be a date in the future'])
    end
  end

  it 'validates stage2 fields when stage1 is complete' do
    expect(build(:early_allocation, stage2_validation: true)).not_to be_valid

    expect(build(:early_allocation, :stage2)).to be_valid
  end

  context 'when extremism seperation is true' do
    subject {
      build(:early_allocation, :stage2, extremism_separation: true, due_for_release_in_less_than_24months: twenty_four_flag)
    }

    context 'when not set' do
      let(:twenty_four_flag) { nil }

      it 'is not valid' do
        expect(subject).not_to be_valid
      end
    end

    context 'when true' do
      let(:twenty_four_flag) { true }

      it 'is valid' do
        expect(subject).to be_valid
      end
    end

    context 'when false' do
      let(:twenty_four_flag) { false }

      it 'is valid' do
        expect(subject).to be_valid
      end
    end
  end

  context 'when extremism seperatikon is not set' do
    subject {
      build(:early_allocation, stage2_validation: true)
    }

    it 'is doesnt validate due_for_release_in_less_than_24months' do
      expect(subject).not_to be_valid
      expect(subject.errors.count).to eq(5)
      expect(subject.errors.messages.count).to eq(5)
    end
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
