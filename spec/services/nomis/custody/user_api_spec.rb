require 'rails_helper'

describe Nomis::Custody::UserApi do
  describe 'List caseloads for staff' do
    it "can get a list of caseloads where they exist",
      vcr: { cassette_name: :custody_staff_api } do

      response = described_class.list_caseloads('RJONES')

      expect(response).not_to be_nil
      expect(response).to be_instance_of(Array)
      expect(response.sort).to match_array(%w[LEI NWEB PVI WEI])
    end
  end
end
