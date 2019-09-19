require 'rails_helper'

RSpec.describe OffenderHelper do
  describe 'Digital Prison Services profile path' do
    it "formats the link to an offender's profile page within the Digital Prison Services" do
      expect(digital_prison_service_profile_path('AB1234A')).to eq("#{Rails.configuration.digital_prison_service_host}/offenders/AB1234A/quick-look")
    end
  end

  describe 'generates labels for case owner ' do
    it 'can show Custody for Prison' do
      off = Nomis::Offender.new
      off.sentence = Nomis::SentenceDetail.new

      expect(case_owner_label(off)).to eq('Custody')
    end

    it 'can show Community for Probation' do
      off = Nomis::Offender.new
      off.sentence = Nomis::SentenceDetail.new
      off.sentence.release_date = Time.zone.today

      expect(case_owner_label(off)).to eq('Community')
    end
  end
end
