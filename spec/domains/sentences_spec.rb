require "rails_helper"

describe Sentences do
  before do
    stub_auth_token
  end

  describe '.for' do
    before { stub_request(:get, "https://prison-api-dev.prison.service.justice.gov.uk/api/offender-sentences/booking/12345678/sentenceTerms").to_return(status: 200, body: results.to_json, headers: {}) }

    let(:results) do
      [
        {
          'bookingId' => 12_345_678,
          'caseId' => 98_765_432,
          'sentenceSequence' => 1,
          'lineSeq' => 1,
          'termSequence' => 1,
          'lifeSentence' => true,
          'sentenceType' => "LR_ALP",
          'sentenceTypeDescription' => "Recall from Automatic Life",
          'sentenceTermCode' => "IMP",
          'sentenceStartDate' => "1993-10-21",
          'startDate' => "1993-10-21",
          'years' => nil,
          'months' => nil,
          'days' => nil
        },
        {
          'bookingId' => 12_345_678,
          'caseId' => 98_765_433,
          'sentenceSequence' => 2,
          'lineSeq' => 2,
          'termSequence' => 1,
          'lifeSentence' => false,
          'sentenceType' => "LR_ALP",
          'sentenceTypeDescription' => "Recall from Automatic Life",
          'sentenceTermCode' => "IMP",
          'sentenceStartDate' => "1993-10-21",
          'startDate' => "1993-10-21",
          'years' => nil,
          'months' => nil,
          'days' => nil
        },
      ]
    end

    it 'returns each result as an instance of Sentences::SentenceSequence' do
      sentences = described_class.for(booking_id: 12_345_678)
      expect(sentences.count).to eq(2)
      expect(sentences.first.class).to eq(Sentences::SentenceSequence)
    end
  end
end
