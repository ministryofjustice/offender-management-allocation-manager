require 'rails_helper'

describe HmppsApi::KeyworkerApi do
  before do
    stub_request(:get, "#{ApiHelper::KEYWORKER_API_HOST}/prisoners/G4273GI/allocations/current")
     .to_return(body: { "prisonNumber" => "G4273GI", "allocations" => [] }.to_json)
  end

  describe 'Keyworkers' do
    it 'calls the keyworker allocations endpoint' do
      offender_no = 'G4273GI'
      response = described_class.get_keyworker(offender_no)

      expect(response['prisonNumber']).to eq('G4273GI')
    end
  end
end
