require 'rails_helper'

describe HmppsApi::PrisonApi::UserApi do
  describe '#user_details' do
    it "can get a user's details",
       vcr: { cassette_name: :elite2_staff_api } do
      response = described_class.user_details('RJONES')

      expect(response).not_to be_nil
      expect(response).to be_kind_of(Nomis::UserDetails)
    end
  end
end
