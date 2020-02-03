require 'rails_helper'

describe RecommendationService do
  let(:tierA) {
    Nomis::OffenderSummary.new.tap { |o|
      o.tier = 'A'
      o.sentence = Nomis::SentenceDetail.new
      o.inprisonment_status = 'SENT03'
    }
  }
  let(:tierD) {
    Nomis::OffenderSummary.new.tap { |o|
      o.tier = 'D'
      o.sentence = Nomis::SentenceDetail.new
      o.inprisonment_status = 'SENT03'
    }
  }

  let(:tierA_and_immigration_case) {
    Nomis::OffenderSummary.new.tap { |o|
      o.tier = 'A'
      o.sentence = Nomis::SentenceDetail.new
      o.inprisonment_status = 'DET'
    }
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
