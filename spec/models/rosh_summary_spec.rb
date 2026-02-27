# frozen_string_literal: true

require 'rails_helper'

RSpec.describe RoshSummary do
  describe '.for' do
    let(:crn) { 'ABC123' }

    context 'when crn is blank' do
      it 'returns unable' do
        result = described_class.for(nil)
        expect(result).to be_unable
      end
    end

    context 'when API returns 404' do
      before do
        allow(
          HmppsApi::AssessRisksAndNeedsApi
        ).to receive(:get_rosh_summary).and_raise(Faraday::ResourceNotFound.new(nil))
      end

      it 'returns missing' do
        result = described_class.for(crn)
        expect(result).to be_missing
      end
    end

    context 'when API returns 403' do
      before do
        allow(
          HmppsApi::AssessRisksAndNeedsApi
        ).to receive(:get_rosh_summary).and_raise(Faraday::ForbiddenError.new(nil))
      end

      it 'returns unable' do
        result = described_class.for(crn)
        expect(result).to be_unable
      end
    end

    context 'when API returns 500' do
      before do
        allow(
          HmppsApi::AssessRisksAndNeedsApi
        ).to receive(:get_rosh_summary).and_raise(Faraday::ServerError.new(nil))
      end

      it 'returns unable' do
        result = described_class.for(crn)
        expect(result).to be_unable
      end
    end

    context 'when API returns blank overallRiskLevel' do
      before do
        allow(
          HmppsApi::AssessRisksAndNeedsApi
        ).to receive(:get_rosh_summary).and_return({ 'summary' => { 'overallRiskLevel' => nil } })
      end

      it 'returns unable' do
        result = described_class.for(crn)
        expect(result).to be_unable
      end
    end

    context 'when API returns a successful response without assessedOn' do
      before do
        allow(HmppsApi::AssessRisksAndNeedsApi).to receive(:get_rosh_summary).and_return(
          { 'summary' => { 'overallRiskLevel' => 'HIGH' } }
        )
      end

      it 'returns found with nil last_updated' do
        result = described_class.for(crn)

        expect(result).to be_found
        expect(result.last_updated).to be_nil
      end
    end

    context 'when API returns a successful response' do
      let(:api_response) do
        {
          'summary' => {
            'riskInCommunity' => {
              'HIGH' => ['Children'],
              'MEDIUM' => ['Public', 'Staff'],
              'LOW' => ['Known Adult']
            },
            'riskInCustody' => {
              'HIGH' => ['Know adult'],
              'VERY_HIGH' => ['Staff', 'Prisoners'],
              'LOW' => ['Children', 'Public']
            },
            'overallRiskLevel' => 'VERY_HIGH'
          },
          'assessedOn' => '2022-07-05T15:29:01',
        }
      end

      before do
        allow(HmppsApi::AssessRisksAndNeedsApi).to receive(:get_rosh_summary).and_return(api_response)
      end

      it 'returns found with parsed data' do
        result = described_class.for(crn)

        expect(result).to be_found
        expect(result.overall).to eq('VERY_HIGH')
        expect(result.last_updated).to eq(Date.new(2022, 7, 5))
        expect(result.custody).to eq(
          children: 'low',
          public: 'low',
          known_adult: 'high',
          staff: 'very_high',
          prisoners: 'very_high'
        )
        expect(result.community).to eq(
          children: 'high',
          public: 'medium',
          known_adult: 'low',
          staff: 'medium',
          prisoners: nil
        )
      end
    end
  end

  describe '.unable' do
    it 'returns an unable summary' do
      result = described_class.unable
      expect(result).to be_unable
      expect(result).not_to be_found
      expect(result).not_to be_missing
      expect(result.overall).to be_nil
    end
  end

  describe '.missing' do
    it 'returns a missing summary' do
      result = described_class.missing
      expect(result).to be_missing
      expect(result).not_to be_found
      expect(result).not_to be_unable
      expect(result.overall).to be_nil
    end
  end
end
