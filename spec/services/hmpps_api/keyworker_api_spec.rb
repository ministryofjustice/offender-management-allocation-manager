require 'rails_helper'

describe HmppsApi::KeyworkerApi do
  let(:offender_no) { 'G4273GI' }

  before do
    stub_request(:get, "#{ApiHelper::KEYWORKER_API_HOST}/prisoners/#{offender_no}/allocations/current")
     .to_return(body: { "prisonNumber" => "G4273GI", "allocations" => [] }.to_json)
  end

  describe 'Keyworkers' do
    it 'calls the keyworker allocations endpoint' do
      response = described_class.get_keyworker(offender_no)

      expect(response['prisonNumber']).to eq(offender_no)
    end
  end

  describe 'error handling' do
    let(:endpoint) { "#{ApiHelper::KEYWORKER_API_HOST}/prisoners/#{offender_no}/allocations/current" }

    context 'when the API returns a server error' do
      before { stub_request(:get, endpoint).to_return(status: 500) }

      it 'returns nil' do
        expect(described_class.get_keyworker(offender_no)).to be_nil
      end

      it 'logs the error' do
        allow(Rails.logger).to receive(:error)
        described_class.get_keyworker(offender_no)
        expect(Rails.logger).to have_received(:error).with(/keyworker_api_error/)
      end
    end

    context 'when the API returns a 401' do
      before { stub_request(:get, endpoint).to_return(status: 401) }

      it 'returns nil' do
        expect(described_class.get_keyworker(offender_no)).to be_nil
      end
    end
  end
end
