# frozen_string_literal: true

require "rails_helper"

describe HmppsApi::TieringApi do
  describe '.get_calculation' do
    let(:crn) { 'X408769' }
    let(:calculation_id) { 'a5e7d3c1-9b4f-4e2a-8c6d-1f3b5a7e9d02' }
    let(:version) { 3 }
    let(:route) { "/v#{version}/crn/#{crn}/tier/#{calculation_id}" }
    let(:client) { instance_double(HmppsApi::Client) }

    before do
      allow(HmppsApi::Client).to receive(:new).and_return(client)
    end

    context 'with version 3' do
      before do
        allow(client).to receive(:get).with(route, cache: false)
          .and_return({ 'tierScore' => 'E', 'calculationDate' => '2024-03-15' })
      end

      it 'returns the parsed tier and date' do
        result = described_class.get_calculation(crn, calculation_id, version:)
        expect(result).to eq(tier: 'E', calculation_date: Date.parse('2024-03-15'))
        expect(client).to have_received(:get).with(route, cache: false)
      end
    end

    context 'with version 2' do
      let(:version) { 2 }

      before do
        allow(client).to receive(:get).with(route, cache: false)
          .and_return({ 'tierScore' => 'D1', 'calculationDate' => '2024-03-15' })
      end

      it 'returns the parsed tier and date' do
        result = described_class.get_calculation(crn, calculation_id, version:)
        expect(result).to eq(tier: 'D1', calculation_date: Date.parse('2024-03-15'))
        expect(client).to have_received(:get).with(route, cache: false)
      end
    end

    context 'when the endpoint returns 404' do
      before do
        allow(client).to receive(:get).with(route, cache: false)
          .and_raise(Faraday::ResourceNotFound.new(nil))
      end

      it 'returns nil' do
        expect(described_class.get_calculation(crn, calculation_id, version:)).to be_nil
      end
    end

    context 'when the endpoint returns a server error' do
      before do
        allow(client).to receive(:get).with(route, cache: false)
          .and_raise(Faraday::ServerError.new(nil))
      end

      it 'returns an error hash' do
        result = described_class.get_calculation(crn, calculation_id, version:)
        expect(result).to eq(tier: nil, calculation_date: nil, error: Faraday::ServerError)
      end

      it 'logs the error' do
        allow(Rails.logger).to receive(:error)
        described_class.get_calculation(crn, calculation_id, version:)
        expect(Rails.logger).to have_received(:error).with(/event=tiering_get_calculation,route=#{route}/)
      end
    end
  end
end
