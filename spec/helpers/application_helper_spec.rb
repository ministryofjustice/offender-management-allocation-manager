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

    it "can choose the correct responsibility label" do
      expect(responsibility_label('Probation')).to eq('Community')
      expect(responsibility_label('Prison')).to eq('Custody')
    end
  end
end


