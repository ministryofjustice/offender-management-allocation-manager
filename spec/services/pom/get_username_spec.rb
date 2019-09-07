require 'rails_helper'

describe POM::GetUsername do
  describe '#get_user_name' do
    it "can get user names",
       vcr: { cassette_name: :pom_service_user_name } do
      fname, lname = described_class.call('RJONES')
      expect(fname).to eq('ROSS')
      expect(lname).to eq('JONES')
    end
  end
end
