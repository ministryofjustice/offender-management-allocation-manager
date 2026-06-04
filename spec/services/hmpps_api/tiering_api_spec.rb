# frozen_string_literal: true

require "rails_helper"

describe HmppsApi::TieringApi do
  describe '.get_calculation' do
    let(:api_host) { Rails.configuration.tiering_api_host }
    let(:crn) { 'X408769' }
    let(:calculation_id) { 'a5e7d3c1-9b4f-4e2a-8c6d-1f3b5a7e9d02' }
    let(:response_body) do
      { 'tierScore' => 'E', 'calculationDate' => '2024-03-15' }.to_json
    end

    context 'with version 3' do
      let(:endpoint) { "#{api_host}/v3/crn/#{crn}/tier/#{calculation_id}" }

      before do
        stub_request(:get, endpoint).to_return(status: 200, body: response_body)
      end

      it 'calls the v3 endpoint' do
        result = described_class.get_calculation(crn, calculation_id, version: 3)
        expect(result).to eq(tier: 'E', calculation_date: Date.parse('2024-03-15'))
        expect(WebMock).to have_requested(:get, endpoint)
      end
    end

    context 'with version 2' do
      let(:endpoint) { "#{api_host}/v2/crn/#{crn}/tier/#{calculation_id}" }
      let(:response_body) do
        { 'tierScore' => 'D1', 'calculationDate' => '2024-03-15' }.to_json
      end

      before do
        stub_request(:get, endpoint).to_return(status: 200, body: response_body)
      end

      it 'calls the v2 endpoint' do
        result = described_class.get_calculation(crn, calculation_id, version: 2)
        expect(result).to eq(tier: 'D1', calculation_date: Date.parse('2024-03-15'))
        expect(WebMock).to have_requested(:get, endpoint)
      end
    end

    context 'when the endpoint returns 404' do
      let(:endpoint) { "#{api_host}/v3/crn/#{crn}/tier/#{calculation_id}" }

      before do
        stub_request(:get, endpoint).to_return(status: 404, body: '')
      end

      it 'returns nil' do
        result = described_class.get_calculation(crn, calculation_id, version: 3)
        expect(result).to be_nil
      end
    end

    context 'when the endpoint returns a server error' do
      let(:endpoint) { "#{api_host}/v3/crn/#{crn}/tier/#{calculation_id}" }

      before do
        stub_request(:get, endpoint).to_return(status: 500, body: 'Internal Server Error')
      end

      it 'returns an error hash' do
        result = described_class.get_calculation(crn, calculation_id, version: 3)
        expect(result).to eq(tier: nil, calculation_date: nil, error: Faraday::ServerError)
      end

      it 'logs the error' do
        allow(Rails.logger).to receive(:error)
        described_class.get_calculation(crn, calculation_id, version: 3)
        expect(Rails.logger).to have_received(:error).with(%r{event=tiering_get_calculation,route=/v3/crn/#{crn}/tier/#{calculation_id}})
      end
    end
  end
end
