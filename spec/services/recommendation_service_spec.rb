require 'rails_helper'

describe RecommendationService do
  before do
    stub_sentence_type(offender.booking_id)
  end

  context 'when tier A' do
    let(:offender) {
      build(:offender_summary,  sentence: Nomis::SentenceDetail.new(
        sentence_start_date: Time.zone.today,
        automatic_release_date: Time.zone.today + 15.months)).tap { |o|
        o.load_case_information(build(:case_information, tier: 'A'))
      }
    }

    it "can determine the best type of POM for Tier A" do
      expect(described_class.recommended_pom_type(offender)).to eq(described_class::PROBATION_POM)
    end
  end

  context 'when tier D' do
    let(:offender) {
      build(:offender_summary,  sentence: Nomis::SentenceDetail.new(
        sentence_start_date: Time.zone.today,
        automatic_release_date: Time.zone.today + 10.months)).tap { |o|
        o.load_case_information(build(:case_information, tier: 'D'))
      }
    }

    it "can determine the best type of POM for Tier D" do
      expect(described_class.recommended_pom_type(tierD)).to eq(described_class::PRISON_POM)
    end
  end

  context 'when tierA and immigration_case' do
    let(:offender) {
      build(:offender_summary,
            inprisonment_status: 'DET', sentence: Nomis::SentenceDetail.new).tap { |o|
        o.load_case_information(build(:case_information, tier: 'A'))
      }
    }

    it "can determine the best type of POM for an immigration case" do
      expect(described_class.recommended_pom_type(offender)).to eq(described_class::PRISON_POM)
    end
  end
end
