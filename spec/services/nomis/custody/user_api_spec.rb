require 'rails_helper'

describe Nomis::Custody::UserApi do
  describe '#user_details' do
    it "can get a user's details",
       vcr: { cassette_name: :custody_staff_api } do
      response = described_class.user_details('RJONES')

      expect(response).not_to be_nil
      expect(response).to be_kind_of(Nomis::Models::UserDetails)
    end
  end
end
