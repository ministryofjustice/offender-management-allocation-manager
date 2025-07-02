require 'rails_helper'

describe HmppsApi::PrisonApi::UserApi do
  describe '#user_details' do
    let(:username) { 'RJONES' }

    before do
      stub_user(username, 123_456)
      stub_pom_emails(123_456, [])
    end

    it "can get a user's details" do
      response = described_class.user_details(username)

      expect(response).not_to be_nil
      expect(response).to be_a(HmppsApi::UserDetails)
    end
  end
end
