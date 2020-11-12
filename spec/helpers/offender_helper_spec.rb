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

  describe 'generates labels for case owner ' do
    it 'can show Custody for Prison' do
      off = build(:offender).tap { |o|
        o.load_case_information(build(:case_information))
        o.sentence = HmppsApi::SentenceDetail.new sentence_start_date: Time.zone.today - 20.months,
                                               automatic_release_date: Time.zone.today + 20.months
      }
      offp = OffenderPresenter.new(off)

      expect(helper.case_owner_label(offp)).to eq('Custody')
    end

    it 'can show Community for Probation' do
      off = build(:offender).tap { |o|
        o.sentence = HmppsApi::SentenceDetail.new automatic_release_date: Time.zone.today
      }
      offp = OffenderPresenter.new(off)

      expect(helper.case_owner_label(offp)).to eq('Community')
    end
  end

  describe 'approaching_handover_without_com?' do
    it 'returns false if offender is not sentenced' do
      offender = build(:offender).tap { |o|
        o.load_case_information(build(:case_information))
        o.sentence = HmppsApi::SentenceDetail.new sentence_start_date: Time.zone.today - 20.months,
                                                  automatic_release_date: Time.zone.today + 20.months
      }

      expect(offender.sentenced?).to eq(false)
      expect(helper.approaching_handover_without_com?(offender)).to eq(false)
    end

    it 'returns false if offender does not have a handover_start_date' do
      offender = build(:offender, :indeterminate).tap { |o|
        o.load_case_information(build(:case_information))
        o.sentence = HmppsApi::SentenceDetail.new sentence_start_date: Time.zone.today + 20.months,
                                                  automatic_release_date: nil
      }

      expect(helper.approaching_handover_without_com?(offender)).to eq(false)
    end

    it 'returns false if offender has more than 45 days until start_of_handover' do
      offender = build(:offender).tap { |o|
        o.load_case_information(build(:case_information))
        o.sentence = HmppsApi::SentenceDetail.new sentence_start_date: Time.zone.today - 20.months,
                                                  automatic_release_date: Time.zone.today + 20.months,
                                                  release_date: Time.zone.today + 20.months
      }

      expect(helper.approaching_handover_without_com?(offender)).to eq(false)
    end

    it "returns false if offender has a 'COM' assigned with 45 days or less until start_of_handover" do
      offender = build(:offender).tap { |o|
        o.load_case_information(build(:case_information, com_name: "Betty White"))
        o.sentence = HmppsApi::SentenceDetail.new sentence_start_date: Time.zone.today - 20.months,
                                                  automatic_release_date: Time.zone.today + 8.months,
                                                  release_date: Time.zone.today + 20.months
      }

      expect(helper.approaching_handover_without_com?(offender)).to eq(false)
    end

    it "returns true if offender has no 'COM' assigned with 45 days or less until the start_of_handover" do
      offender = build(:offender).tap { |o|
        o.load_case_information(build(:case_information))
        o.sentence = HmppsApi::SentenceDetail.new sentence_start_date: Time.zone.today - 20.months,
                                                  automatic_release_date: Time.zone.today + 8.months,
                                                  release_date: Time.zone.today + 20.months
      }

      expect(helper.approaching_handover_without_com?(offender)).to eq(true)
    end
  end
end
