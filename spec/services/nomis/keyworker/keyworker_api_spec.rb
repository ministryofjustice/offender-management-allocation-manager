require 'rails_helper'

describe Nomis::Keyworker::KeyworkerApi do
  describe 'Keyworkers' do
    let(:location) { 'LEI' }

    it 'can get details for a Keyworker',
      vcr: { cassette_name: :keyworker_api_details_spec } do
      offender_no = 'G4273GI'
      response = described_class.get_keyworker(location, offender_no)

      expect(response).to be_instance_of(Nomis::Models::KeyworkerDetails)
    end

    it 'returns null if unable find a Keyworker', :raven_intercept_exception,
      vcr: { cassette_name: :keyworker_api_details_not_found_spec } do
      unknown_offender_no = 'GGGGGGG'
      response = described_class.get_keyworker(location, unknown_offender_no)

      expect(response).to be_instance_of(Nomis::Models::NullKeyworker)
    end
  end
end
