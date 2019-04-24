require 'rails_helper'

RSpec.describe ApplicationHelper do
  describe 'formatting date strings' do
    it "will parse dates into strings" do
      expect(format_date_string('1973-02-21')).to eq('21/02/1973')
    end
  end

  describe 'returns the correct label' do
    it "for service provider CRC" do
      expect(service_provider_label('CRC')).to eq('Community Rehabilitation Company (CRC)')
    end

    it "for service provider NPS" do
      expect(service_provider_label('NPS')).to eq('National Probation Service (NPS)')
    end
  end

  describe 'generates labels for case owner ' do
    it 'can show Custody for Prison' do
      off = Nomis::Models::Offender.new
      off.sentence = Nomis::Models::SentenceDetail.new

      expect(case_owner_label(off)).to eq('Custody')
    end

    it 'can show Community for Probation' do
      off = Nomis::Models::Offender.new
      off.sentence = Nomis::Models::SentenceDetail.new
      off.sentence.release_date = Time.zone.today

      expect(case_owner_label(off)).to eq('Community')
    end
  end
end
