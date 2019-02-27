require 'rails_helper'

RSpec.describe GaHelper do
  describe 'analytics tag available' do
    it "can tell when analytics is available" do
      Rails.configuration.ga_tracking_id = 'A'
      expect(ga_enabled?).to be true
      Rails.configuration.ga_tracking_id = nil
      expect(ga_enabled?).to be false
    end

    it "can make the tracking ID available" do
      Rails.configuration.ga_tracking_id = 'A'
      expect(ga_tracking_id).to eq('A')
      Rails.configuration.ga_tracking_id = 'A  '
      expect(ga_tracking_id).to eq('A')
      Rails.configuration.ga_tracking_id = nil
    end
  end
end
