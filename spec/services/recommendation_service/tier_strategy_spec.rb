require 'rails_helper'

describe RecommendationService::TierStrategy do
  let(:prison) { build(:prison) }
  let(:api_offender) { build(:hmpps_api_offender, sentence: attributes_for(:sentence_detail, :determinate_release_in_three_years)) }
  let(:case_info) { build(:case_information, tier: tier) }
  let(:offender) { build(:mpc_offender, prison: prison, offender: case_info.offender, prison_record: api_offender) }
  let(:tier) { 'A' }

  described_class::HIGH_TIERS.each do |t|
    context "when tier #{t}" do
      let(:tier) { t }

      it 'recommends a probation POM' do
        expect(described_class.recommended_pom_type(offender)).to eq(RecommendationService::PROBATION_POM)
      end

      it 'gives a tier-based reason mentioning probation POM' do
        expect(described_class.recommended_pom_type_reason(offender)).to include("is tier #{t}", 'probation POM')
      end
    end
  end

  context 'when tier C' do
    let(:tier) { 'C' }

    it 'recommends a prison POM' do
      expect(described_class.recommended_pom_type(offender)).to eq(RecommendationService::PRISON_POM)
    end

    it 'gives a tier-based reason mentioning prison POM' do
      expect(described_class.recommended_pom_type_reason(offender)).to include('is tier C', 'prison POM')
    end
  end

  context 'when immigration case' do
    let(:api_offender) do
      build(:hmpps_api_offender,
            sentence: attributes_for(:sentence_detail, imprisonmentStatus: 'DET', sentenceStartDate: Time.zone.today))
    end

    it 'recommends a prison POM' do
      expect(described_class.recommended_pom_type(offender)).to eq(RecommendationService::PRISON_POM)
    end

    it 'gives the immigration reason' do
      expect(described_class.recommended_pom_type_reason(offender)).to include('immigration case')
    end
  end

  context 'when POM is not in a responsible role' do
    before do
      allow(offender).to receive(:pom_responsible?).and_return(false)
    end

    it 'recommends a prison POM' do
      expect(described_class.recommended_pom_type(offender)).to eq(RecommendationService::PRISON_POM)
    end

    it 'gives the supporting role reason' do
      expect(described_class.recommended_pom_type_reason(offender)).to include('needs a POM in a supporting role', 'prison POM')
    end
  end
end
