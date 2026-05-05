require 'rails_helper'

describe RecommendationService::RoshStrategy do
  let(:prison) { build(:prison) }
  let(:api_offender) { build(:hmpps_api_offender, sentence: attributes_for(:sentence_detail, :determinate_release_in_three_years)) }
  let(:case_info) { build(:case_information, tier: tier, rosh_level: rosh_level) }
  let(:offender) { build(:mpc_offender, prison: prison, offender: case_info.offender, prison_record: api_offender) }
  let(:tier) { 'B' }
  let(:rosh_level) { 'HIGH' }

  context 'when tier A' do
    let(:tier) { 'A' }
    let(:rosh_level) { 'LOW' }

    it 'recommends a probation POM regardless of ROSH' do
      expect(described_class.recommended_pom_type(offender)).to eq(RecommendationService::PROBATION_POM)
    end

    it 'gives the tier A reason' do
      expect(described_class.recommended_pom_type_reason(offender)).to include('tier A')
    end
  end

  described_class::HIGH_ROSH_LEVELS.each do |level|
    context "with #{level} ROSH" do
      let(:rosh_level) { level }

      it 'recommends a probation POM' do
        expect(described_class.recommended_pom_type(offender)).to eq(RecommendationService::PROBATION_POM)
      end

      it 'gives the ROSH reason' do
        expect(described_class.recommended_pom_type_reason(offender)).to include("has a #{level.humanize.downcase} ROSH", 'probation POM')
      end
    end
  end

  context 'with medium ROSH' do
    let(:rosh_level) { 'MEDIUM' }

    it 'recommends a prison POM' do
      expect(described_class.recommended_pom_type(offender)).to eq(RecommendationService::PRISON_POM)
    end

    it 'gives the ROSH reason' do
      expect(described_class.recommended_pom_type_reason(offender)).to include('has a medium ROSH', 'prison POM')
    end
  end

  context 'with low ROSH' do
    let(:rosh_level) { 'LOW' }

    it 'recommends a prison POM' do
      expect(described_class.recommended_pom_type(offender)).to eq(RecommendationService::PRISON_POM)
    end

    it 'gives the ROSH reason' do
      expect(described_class.recommended_pom_type_reason(offender)).to include('has a low ROSH', 'prison POM')
    end
  end

  context 'with no ROSH level' do
    let(:rosh_level) { nil }

    it 'recommends a prison POM' do
      expect(described_class.recommended_pom_type(offender)).to eq(RecommendationService::PRISON_POM)
    end

    it 'gives the reason with N/A' do
      expect(described_class.recommended_pom_type_reason(offender)).to include('has a N/A ROSH', 'prison POM')
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
