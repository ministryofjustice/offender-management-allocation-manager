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
      let(:offender) { build(:offender, :determinate_recall) }

      it 'shows supporting' do
        expect(helper.pom_responsibility_label(offender)).to eq('Supporting')
      end
    end

    context 'when unknown' do
      let(:offender) { build(:offender, sentence: build(:sentence_detail, :unsentenced, conditionalReleaseDate: nil)) }

      it 'shows unknown' do
        expect(helper.pom_responsibility_label(offender)).to eq('Unknown')
      end
    end
  end

  describe 'generates labels for case owner ' do
    it 'can show Custody for Prison' do
      off = build(:offender).tap { |o|
        o.load_case_information(build(:case_information))
        o.sentence = HmppsApi::SentenceDetail.from_json('sentenceStartDate' => (Time.zone.today - 20.months).to_s,
                                                         'automaticReleaseDate' => (Time.zone.today + 20.months).to_s)
      }
      offp = OffenderPresenter.new(off)

      expect(helper.case_owner_label(offp)).to eq('Custody')
    end

    it 'can show Community for Probation' do
      off = build(:offender).tap { |o|
        o.sentence = HmppsApi::SentenceDetail.from_json("automaticReleaseDate" => Time.zone.today.to_s)
      }
      offp = OffenderPresenter.new(off)

      expect(helper.case_owner_label(offp)).to eq('Community')
    end

    context 'when unknown' do
      let(:offender) { build(:offender, sentence: build(:sentence_detail, :unsentenced, conditionalReleaseDate: nil)) }

      it 'can show Unknown' do
        expect(helper.case_owner_label(offender)).to eq('Unknown')
      end
    end
  end
end
