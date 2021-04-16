require 'rails_helper'

describe RecommendationService do
  context 'when tier A' do
    let(:tier_a) {
      build(:offender,
            sentence: build(:sentence_detail, :blank,
                            sentenceStartDate: Time.zone.today,
                            automaticReleaseRate: Time.zone.today + 15.months)).tap { |o|
        o.load_case_information(build(:case_information, tier: 'A'))
      }
    }

    it "can determine the best type of POM for Tier A" do
      expect(described_class.recommended_pom_type(tier_a)).to eq(described_class::PROBATION_POM)
    end
  end

  context 'when tier D' do
    let(:tier_d) {
      build(:offender,
            sentence: build(:sentence_detail,
                            sentenceStartDate: Time.zone.today,
                            automaticReleaseDate: Time.zone.today + 10.months)).tap { |o|
        o.load_case_information(build(:case_information, tier: 'D'))
      }
    }

    it "can determine the best type of POM for Tier D" do
      expect(described_class.recommended_pom_type(tier_d)).to eq(described_class::PRISON_POM)
    end
  end

  context 'when tier A immigration case' do
    let(:tier_a_and_immigration_case) {
      build(:offender,
            imprisonmentStatus: 'DET', sentence: build(:sentence_detail, sentenceStartDate: Time.zone.today)).tap { |o|
        o.load_case_information(build(:case_information, tier: 'A'))
      }
    }

    it "can determine the best type of POM for an immigration case" do
      expect(described_class.recommended_pom_type(tier_a_and_immigration_case)).to eq(described_class::PRISON_POM)
    end
  end
end
