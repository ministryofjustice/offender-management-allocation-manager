require 'rails_helper'

RSpec.describe OffenderPresenter do
  describe '#complex_reason_label' do
    context 'when a prison POM' do
      # we need to set up this test to return a Prison POM recommendation; we are using an
      # Immigration case as they are always recommended to Prison POMs
      let(:subject) { described_class.new(OpenStruct.new(immigration_case?: true, nps_case?: false)) }

      it "can get for a prison owned offender" do
        expect(subject.complex_reason_label).to eq('Prisoner assessed as not suitable for a prison officer POM')
      end
    end

    context 'when a probation POM' do
      it "can get for a probation owned offender" do
        offender = build(:offender,  :indeterminate)
        offender.tier = 'A'
        subject = described_class.new(offender)
        expect(subject.complex_reason_label).to eq('Prisoner assessed as suitable for a prison officer POM despite tiering calculation')
      end
    end
  end

  describe '#responsibility_override?' do
    it 'returns false when no responsibility found for offender' do
      subject = described_class.new(OpenStruct.new(immigration_case?: false, nps_case?: false, responsibility: nil))

      expect(subject.responsibility_override?).to eq(false)
    end

    it 'returns true when there is a responsibility found for an offender' do
      create(:case_information, nomis_offender_id: 'A1234XX')
      resp = create(:responsibility, nomis_offender_id: 'A1234XX')
      subject = described_class.new(OpenStruct.new(offender_no: 'A1234XX', immigration_case?: false, nps_case?: false, responsibility: resp))

      expect(subject.responsibility_override?).to eq(true)
    end
  end

  describe '#recommended_pom_type_label' do
    it "returns 'Prison officer' if RecommendService is PRISON_POM" do
      allow(RecommendationService).to receive(:recommended_pom_type).and_return(RecommendationService::PRISON_POM)
      subject = described_class.new(OpenStruct.new(immigration_case?: true, nps_case?: false, responsibility: nil))

      expect(subject.recommended_pom_type_label).to eq('Prison officer')
    end

    it "returns 'Probation officer' if RecommendService is PROBATION_POM" do
      allow(RecommendationService).to receive(:recommended_pom_type).and_return(RecommendationService::PROBATION_POM)
      subject = described_class.new(OpenStruct.new(immigration_case?: false, nps_case?: true, tier: 'A', responsibility: nil))

      expect(subject.recommended_pom_type_label).to eq('Probation officer')
    end
  end

  describe '#non_recommended_pom_type_label' do
    it "returns 'Probation officer' when RecommendationService is PRISON_POM" do
      allow(RecommendationService).to receive(:recommended_pom_type).and_return(RecommendationService::PRISON_POM)
      subject = described_class.new(OpenStruct.new(immigration_case?: false, nps_case?: false, responsibility: nil))

      expect(subject.non_recommended_pom_type_label).to eq('Probation officer')
    end

    it "returns 'Prison officer' when RecommendationServicce is PROBATION_POM" do
      allow(RecommendationService).to receive(:recommended_pom_type).and_return(RecommendationService::PROBATION_POM)
      subject = described_class.new(OpenStruct.new(immigration_case?: false, nps_case?: false, responsibility: nil))

      expect(subject.non_recommended_pom_type_label).to eq('Prison officer')
    end
  end
end
