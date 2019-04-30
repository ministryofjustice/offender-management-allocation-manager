require 'rails_helper'

RSpec.describe OffenderHelper do
  describe 'new nomis profile path' do
    it "formats the link to an offender's NN profile page" do
      expect(new_nomis_profile_path('AB1234A')).to eq("#{Rails.configuration.new_nomis_host}/offenders/AB1234A/quick-look")
    end
  end
end
