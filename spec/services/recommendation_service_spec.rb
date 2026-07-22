require 'rails_helper'

describe RecommendationService do
  let(:prison) { build(:prison) }
  let(:api_offender) { build(:hmpps_api_offender, sentence: attributes_for(:sentence_detail, :determinate_release_in_three_years)) }
  let(:case_info) { build(:case_information, tier: 'A') }
  let(:offender) { build(:mpc_offender, prison: prison, offender: case_info.offender, prison_record: api_offender) }

  context 'when rosh_recommendations feature flag is disabled' do
    before { stub_feature_flag(:rosh_recommendations, enabled: false) }

    it 'delegates recommended_pom_type to TierStrategy' do
      expect(described_class::TierStrategy).to receive(:recommended_pom_type).with(offender).and_call_original
      described_class.recommended_pom_type(offender)
    end

    it 'delegates recommended_pom_type_reason to TierStrategy' do
      expect(described_class::TierStrategy).to receive(:recommended_pom_type_reason).with(offender).and_call_original
      described_class.recommended_pom_type_reason(offender)
    end
  end

  context 'when rosh_recommendations feature flag is enabled' do
    before { stub_feature_flag(:rosh_recommendations, enabled: true) }

    it 'delegates recommended_pom_type to RoshStrategy' do
      expect(described_class::RoshStrategy).to receive(:recommended_pom_type).with(offender).and_call_original
      described_class.recommended_pom_type(offender)
    end

    it 'delegates recommended_pom_type_reason to RoshStrategy' do
      expect(described_class::RoshStrategy).to receive(:recommended_pom_type_reason).with(offender).and_call_original
      described_class.recommended_pom_type_reason(offender)
    end

    describe '.recommendation_available?' do
      it 'returns true when a recommendation exists' do
        expect(described_class.recommendation_available?(offender)).to be(true)
      end

      context 'when RoSH is missing and tier is not A' do
        let(:case_info) { build(:case_information, tier: 'B', rosh_level: nil) }

        it 'returns false' do
          expect(described_class.recommendation_available?(offender)).to be(false)
        end
      end
    end
  end
end
