require 'rails_helper'

RSpec.describe ApplicationHelper do
  describe 'formatting date strings' do
    it "will parse dates into strings" do
      expect(format_date_string('1973-02-21')).to eq('21/02/1973')
    end

    it 'displays a date object into a specific string format' do
      date = '2019-07-9T08:54:07'.to_datetime
      expect(format_date_long(date)).to eq('9th July 2019 (08:54)')
    end
  end

  describe 'returns the correct label' do
    it "for service provider CRC" do
      expect(service_provider_label('CRC')).to eq('Community Rehabilitation Company (CRC)')
    end

    it "for service provider NPS" do
      expect(service_provider_label('NPS')).to eq('National Probation Service (NPS)')
    end

    it "for N/A service provider" do
      expect(service_provider_label('N/A')).to eq('N/A')
    end
  end

  describe 'displays mail_to link of a given email' do
    it 'displays alternative text if email not present' do
      email = nil

      expect(format_email(email)).to eq('(email address not found)')
    end

    it 'displays email address as mail_to link' do
      email = 'john.doe@example.com'

      expect(format_email(email)).to eq("<a href=\"mailto:john.doe@example.com\">john.doe@example.com</a>")
    end
  end
end
