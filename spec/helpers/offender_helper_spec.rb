require 'rails_helper'

RSpec.describe OffenderHelper do
  describe 'Digital Prison Services profile path' do
    it "formats the link to an offender's profile page within the Digital Prison Services" do
      expect(digital_prison_service_profile_path('AB1234A')).to eq("#{Rails.configuration.digital_prison_service_host}/offenders/AB1234A/quick-look")
    end
  end

  describe '#event_type' do
    let(:nomis_staff_id) { 456_789 }
    let(:nomis_offender_id) { 123_456 }

    let!(:allocation) {
      create(
        :allocation,
        nomis_offender_id: nomis_offender_id,
        primary_pom_nomis_id: nomis_staff_id,
        event: 'allocate_primary_pom'
      )
    }

    it 'returns the event in a more readable format' do
      expect(helper.last_event(allocation)).to eq("POM allocated - #{allocation.updated_at.strftime('%d/%m/%Y')}")
    end
  end

  describe '#pom_responsibility_label' do
    context 'when responsible' do
      let(:offender) { build(:offender) }

      it 'shows responsible' do
        expect(helper.pom_responsibility_label(offender)).to eq('Responsible')
      end
    end

    context 'when supporting' do
      let(:offender) { build(:offender, sentence: build(:sentence_detail, :determinate_recall)) }

      it 'shows supporting' do
        expect(helper.pom_responsibility_label(offender)).to eq('Supporting')
      end
    end

    context 'when unknown' do
      let(:offender) {
        build(:offender, sentence: build(:sentence_detail, :unsentenced)).tap { |o|
          o.load_case_information(build(:case_information))
        }
      }

      it 'shows unknown' do
        expect(helper.pom_responsibility_label(offender)).to eq('Unknown')
      end
    end
  end

  describe 'generates labels for case owner ' do
    it 'can show Custody for Prison' do
      off = build(:offender).tap { |o|
        o.load_case_information(build(:case_information))
        o.sentence = build(:sentence_detail,
                           sentenceStartDate: Time.zone.today - 20.months,
                           automaticReleaseDate: Time.zone.today + 20.months)
      }

      expect(helper.case_owner_label(off)).to eq('Custody')
    end

    it 'can show Community for Probation' do
      off = build(:offender).tap { |o|
        o.sentence = build(:sentence_detail, automaticReleaseDate: Time.zone.today)
      }

      expect(helper.case_owner_label(off)).to eq('Community')
    end

    context 'when unknown' do
      let(:offender) {
        build(:offender, sentence: build(:sentence_detail, :unsentenced)).tap { |o|
          o.load_case_information(build(:case_information))
        }
      }

      it 'can show Unknown' do
        expect(helper.case_owner_label(offender)).to eq('Unknown')
      end
    end
  end

  describe '#recommended_pom_type_label' do
    it "returns 'Prison officer' if RecommendService is PRISON_POM" do
      allow(RecommendationService).to receive(:recommended_pom_type).and_return(RecommendationService::PRISON_POM)
      subject = OpenStruct.new(immigration_case?: true, nps_case?: false, responsibility: nil)

      expect(helper.recommended_pom_type_label(subject)).to eq('Prison officer')
    end

    it "returns 'Probation officer' if RecommendService is PROBATION_POM" do
      allow(RecommendationService).to receive(:recommended_pom_type).and_return(RecommendationService::PROBATION_POM)
      subject = OpenStruct.new(immigration_case?: false, nps_case?: true, tier: 'A', responsibility: nil)

      expect(helper.recommended_pom_type_label(subject)).to eq('Probation officer')
    end
  end

  describe '#complex_reason_label' do
    context 'when a prison POM' do
      # we need to set up this test to return a Prison POM recommendation; we are using an
      # Immigration case as they are always recommended to Prison POMs
      let(:subject) { OpenStruct.new(immigration_case?: true, nps_case?: false) }

      it "can get for a prison owned offender" do
        expect(helper.complex_reason_label(subject)).to eq('Prisoner assessed as not suitable for a prison officer POM')
      end
    end

    context 'when a probation POM' do
      it "can get for a probation owned offender" do
        offender = build(:offender, sentence: build(:sentence_detail, :indeterminate))
        case_info = build(:case_information, tier: 'A')
        offender.load_case_information(case_info)
        expect(helper.complex_reason_label(offender)).to eq('Prisoner assessed as suitable for a prison officer POM despite tiering calculation')
      end
    end
  end

  describe '#non_recommended_pom_type_label' do
    it "returns 'Probation officer' when RecommendationService is PRISON_POM" do
      allow(RecommendationService).to receive(:recommended_pom_type).and_return(RecommendationService::PRISON_POM)
      subject = OpenStruct.new(immigration_case?: false, nps_case?: false, responsibility: nil)

      expect(helper.non_recommended_pom_type_label(subject)).to eq('Probation officer')
    end

    it "returns 'Prison officer' when RecommendationServicce is PROBATION_POM" do
      allow(RecommendationService).to receive(:recommended_pom_type).and_return(RecommendationService::PROBATION_POM)
      subject = OpenStruct.new(immigration_case?: false, nps_case?: false, responsibility: nil)

      expect(helper.non_recommended_pom_type_label(subject)).to eq('Prison officer')
    end
  end
end
