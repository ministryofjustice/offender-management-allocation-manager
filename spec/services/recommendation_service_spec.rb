require 'rails_helper'

describe RecommendationService do
  context 'when tier A' do
    let(:tierA) {
      build(:offender_summary, tier: 'A', sentence: Nomis::SentenceDetail.new(
        sentence_start_date: Time.zone.today,
        automatic_release_date: Time.zone.today + 15.months))
    }

    it "can determine the best type of POM" do
      expect(described_class.recommended_pom_type(tierA)).to eq(described_class::PROBATION_POM)
    end
  end

  context 'when tier D' do
    let(:tierD) {
      build(:offender_summary, tier: 'D', sentence: Nomis::SentenceDetail.new(
        sentence_start_date: Time.zone.today,
        automatic_release_date: Time.zone.today + 10.months))
    }

    it "can determine the best type of POM for Tier D" do
      expect(described_class.recommended_pom_type(tierD)).to eq(described_class::PRISON_POM)
    end
  end

  context 'without tier' do
    subject {
      build(:offender_summary, tier: 'N/A', sentence: Nomis::SentenceDetail.new(
        sentence_start_date: Time.zone.today,
        automatic_release_date: Time.zone.today + 10.months))
    }

    it "can determine the best type of POM" do
      expect(described_class.recommended_pom_type(subject)).to eq(described_class::PRISON_POM)
    end
  end

  context 'when immigration case' do
    let(:tierA_and_immigration_case) {
      build(:offender_summary, tier: 'A', inprisonment_status: 'DET', sentence: Nomis::SentenceDetail.new)
    }

    it "can determine the best type of POM for an immigration case" do
      expect(described_class.recommended_pom_type(tierA_and_immigration_case)).to eq(described_class::PRISON_POM)
    end
  end
end
