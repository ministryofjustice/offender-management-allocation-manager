# frozen_string_literal: true

require 'rails_helper'

RSpec.describe EarlyAllocation, type: :model do
  it 'validates 2nd level booleans when first ones present' do
    expect(build(:early_allocation)).to be_valid
  end

  context 'when oasys date 3 months in the past' do
    let(:ea) { build(:early_allocation_date_form, oasys_risk_assessment_date: Time.zone.today - 3.months + 1.day) }

    it 'is valid' do
      expect(ea).to be_valid
    end
  end

  context 'when oasys date more than 3 months in the past' do
    let(:ea) { build(:early_allocation_date_form, oasys_risk_assessment_date: Time.zone.today - 3.months) }

    it 'validates' do
      expect(ea).not_to be_valid
      expect(ea.errors.full_messages_for(:oasys_risk_assessment_date)).to eq(['This date must be in the last 3 months'])
    end
  end

  context 'when oasys date is in the future' do
    let(:ea) { build(:early_allocation_date_form, oasys_risk_assessment_date: Time.zone.today + 1.day) }

    it 'validates' do
      expect(ea).not_to be_valid
      expect(ea.errors.full_messages_for(:oasys_risk_assessment_date)).to eq(['This must not be a date in the future'])
    end
  end

  it 'validates discretionary fields when eligible is complete' do
    expect(build(:early_allocation_discretionary_form)).not_to be_valid

    expect(build(:early_allocation_discretionary_form, :discretionary)).to be_valid
  end

  context 'when extremism seperation is true' do
    subject {
      build(:early_allocation_discretionary_form, :discretionary, extremism_separation: true, due_for_release_in_less_than_24months: twenty_four_flag)
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

  context 'when extremism seperation is not set' do
    subject {
      build(:early_allocation_discretionary_form)
    }

    it 'is doesnt validate due_for_release_in_less_than_24months' do
      expect(subject).not_to be_valid
      expect(subject.errors.count).to eq(5)
      expect(subject.errors.messages.count).to eq(5)
    end
  end

  it 'validates discretionary attributes' do
    expect(build(:early_allocation, :discretionary)).to be_valid
  end

  describe '#eligible?' do
    it 'is not eligible (actually unsure) if all of the eligible booleans are false' do
      expect(build(:early_allocation, :discretionary).eligible?).to eq(false)
    end

    it 'is eligible if any eligible boolean is true' do
      expect(build(:early_allocation, convicted_under_terrorisom_act_2000: true).eligible?).to eq(true)
    end
  end

  describe '#ineligible?' do
    context 'when eligible (default)' do
      subject { build(:early_allocation).ineligible? }

      it 'is not ineligible (actually unsure) if all of the eligible booleans are false' do
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

  describe '#active_pre_referral_window' do
    it 'selects only those assessments that are NOT ineligible and were created before the referral window' do
      discretionary_outside_referral = create(:early_allocation, :discretionary, outcome: 'discretionary', created_within_referral_window: false)
      eligible_outside_referral = create(:early_allocation, created_within_referral_window: false)
      create(:early_allocation, :ineligible)
      create(:early_allocation, :discretionary, created_within_referral_window: true)
      create(:early_allocation, created_within_referral_window: true)

      expect(described_class.active_pre_referral_window).to match_array([discretionary_outside_referral,
                                                                         eligible_outside_referral])
    end
  end

  describe '#early_allocation?' do
    let(:prison) { build(:prison) }
    let(:api_offender) {
      build(:hmpps_api_offender,
            sentence: build(:sentence_detail, sentenceStartDate: Time.zone.today - 1.week))
    }
    let(:offender) { build(:mpc_offender, prison: prison, offender: case_info.offender, prison_record: api_offender) }

    let(:case_info) {
      create(:case_information, offender: build(:offender,
                                                early_allocations: [build(:early_allocation, :eligible, created_at: assessment_date)]))
    }


    context 'when early allocations comes before the current sentence start date' do
      let(:assessment_date) { Time.zone.today - 2.weeks }

      it 'ignores them' do
        expect(offender.early_allocation?).to eq(false)
      end
    end

    context 'when early allocations come after the current sentence start date' do
      let(:assessment_date) { Time.zone.today }

      it 'doesnt ignores them' do
        expect(offender.early_allocation?).to eq(true)
      end
    end
  end
end
