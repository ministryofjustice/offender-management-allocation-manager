require 'rails_helper'

describe RecommendationService do
  let(:prison) { build(:prison) }

  context 'when tier A' do
    let(:api_offender) {
      build(:hmpps_api_offender,
            sentence: build(:sentence_detail, :blank,
                            sentenceStartDate: Time.zone.today,
                            automaticReleaseRate: Time.zone.today + 15.months))
    }
    let(:case_info) { build(:case_information, tier: 'A') }
    let(:offender) { build(:mpc_offender, prison: prison, offender: case_info.offender, prison_record: api_offender) }

    it "can determine the best type of POM for Tier A" do
      expect(described_class.recommended_pom_type(offender)).to eq(described_class::PROBATION_POM)
    end
  end

  context 'when tier D' do
    let(:api_offender) {
      build(:hmpps_api_offender,
            sentence: build(:sentence_detail,
                            sentenceStartDate: Time.zone.today,
                            automaticReleaseDate: Time.zone.today + 10.months))
    }
    let(:case_info) { build(:case_information, tier: 'D') }
    let(:offender) { build(:mpc_offender, prison: prison, offender: case_info.offender, prison_record: api_offender) }

    it "can determine the best type of POM for Tier D" do
      expect(described_class.recommended_pom_type(offender)).to eq(described_class::PRISON_POM)
    end
  end

  context 'when tier A immigration case' do
    let(:api_offender) {
      build(:hmpps_api_offender,
            sentence: build(:sentence_detail, imprisonmentStatus: 'DET', sentenceStartDate: Time.zone.today))
    }
    let(:case_info) { build(:case_information, tier: 'A') }
    let(:offender) { build(:mpc_offender, prison: prison, offender: case_info.offender, prison_record: api_offender) }

    it "can determine the best type of POM for an immigration case" do
      expect(described_class.recommended_pom_type(offender)).to eq(described_class::PRISON_POM)
    end
  end
end
