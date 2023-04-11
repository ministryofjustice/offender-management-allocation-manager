require 'rails_helper'

RSpec.describe ApplicationHelper do
  describe 'formatting date strings' do
    it 'displays a date object into a specific string format' do
      date = Time.zone.parse '2019-07-9T08:54:07'
      expect(format_date_long(date)).to eq('9th July 2019 (08:54)')
    end
  end

  describe 'returns the correct label' do
    it "for service provider CRC" do
      expect(service_provider_label('CRC')).to eq('CRC (Legacy)')
    end

    it "for service provider NPS" do
      expect(service_provider_label('NPS')).to eq('NPS (Legacy)')
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

  describe 'displays long POM level' do
    let(:po) { 'PO' }
    let(:pom) { 'PRO' }
    let(:staff) { 'STAFF' }

    it 'returns long Probation Officer' do
      expect(pom_level_long(po)).to eq('Probation Officer POM')
    end

    it 'returns long Prison Officer' do
      expect(pom_level_long(pom)).to eq('Prison Officer POM')
    end

    it 'returns long Staff member' do
      expect(pom_level_long(staff)).to eq('N/A')
    end
  end

  describe 'displays correct shortened POM level' do
    it 'show PO level' do
      expect(pom_level('PO')).to eq('Probation POM')
    end

    it 'shows POM level' do
      expect(pom_level('PRO')).to eq('Prison POM')
    end

    it 'shows staff fallback label' do
      expect(pom_level('STAFF')).to eq('N/A')
    end
  end

  describe 'displays correct POM level' do
    it 'show PO level' do
      expect(pom_level_long('PO')).to eq('Probation Officer POM')
    end

    it 'shows POM level' do
      expect(pom_level_long('PRO')).to eq('Prison Officer POM')
    end

    it 'shows staff fallback label' do
      expect(pom_level_long('STAFF')).to eq('N/A')
    end
  end
end
