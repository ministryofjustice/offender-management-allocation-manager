require 'rails_helper'

describe RecommendationService do
  let(:tierA) {
    build(:offender_summary, tier: 'A', sentence: Nomis::SentenceDetail.new(
      sentence_start_date: Time.zone.today,
      automatic_release_date: Time.zone.today + 15.months))
  }
  let(:tierD) {
    build(:offender_summary, tier: 'D', sentence: Nomis::SentenceDetail.new(
      sentence_start_date: Time.zone.today,
      automatic_release_date: Time.zone.today + 10.months))
  }

  let(:tierA_and_immigration_case) {
    build(:offender_summary, tier: 'A', inprisonment_status: 'DET', sentence: Nomis::SentenceDetail.new)
  }

  it "can determine the best type of POM for Tier A" do
    expect(described_class.recommended_pom_type(tierA)).to eq(described_class::PROBATION_POM)
  end

  it "can determine the best type of POM for Tier D" do
    expect(described_class.recommended_pom_type(tierD)).to eq(described_class::PRISON_POM)
  end

  it "can determine the best type of POM for an immigration case" do
    expect(described_class.recommended_pom_type(tierA_and_immigration_case)).to eq(described_class::PRISON_POM)
  end
end
