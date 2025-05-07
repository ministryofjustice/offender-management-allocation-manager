require 'rails_helper'

describe HmppsApi::PrisonApi::UserApi do
  describe '#user_details' do
    it "can get a user's details",
       vcr: { cassette_name: 'prison_api/elite2_staff_api' } do
      response = described_class.user_details('RJONES')

      expect(response).not_to be_nil
      expect(response).to be_a(HmppsApi::UserDetails)
    end
  end
end
