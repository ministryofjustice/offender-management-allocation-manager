describe HmppsApi::AssessRisksAndNeedsApi do
  let(:api_host) { Rails.configuration.assess_risks_and_needs_api_host }

  before do
    stub_auth_token
  end

  describe '.get_latest_oasys_date' do
    let(:offender_no) { 'A9346AC' }

    let(:stub_url) { "#{api_host}/assessments/timeline/nomisId/#{offender_no}" }

    context 'when there is one completed LAYER_3 OASys assessment' do
      let(:completed_date) { '2012-12-22'.to_date }

      let(:response) do
        {
          "timeline" => [
            {
              "completedDate" => "2015-12-06T10:53:44",
              "assessmentType" => "TR_BCS",
              "status" => "COMPLETE"
            },
            {
              "completedDate" => "2012-12-22T14:20:42",
              "assessmentType" => "LAYER_3",
              "status" => "COMPLETE"
            }
          ]
        }.to_json
      end

      before do
        stub_request(:get, stub_url).to_return(status: 200, body: response)
      end

      it 'checks that the API has only been called once' do
        described_class.get_latest_oasys_date(offender_no)
        expect(a_request(:get, stub_url)).to have_been_made.once
      end

      it 'returns the date the assessment was completed for LAYER_3' do
        expect(described_class.get_latest_oasys_date(offender_no)).to match(assessment_type: "LAYER_3", completed: completed_date)
      end
    end

    context 'when there is one completed LAYER_1 OASys assessment' do
      # The last assessment date is the 'completed' field.
      # The test expects it to be a date object for consistency throughout the code base
      let(:completed_date) { '2012-12-22'.to_date }

      let(:response) do
        {
          "timeline" => [
            {
              "completedDate" => "2015-12-06T10:53:44",
              "assessmentType" => "TR_BCS",
              "status" => "COMPLETE"
            },
            {
              "completedDate" => "2012-12-22T14:20:42",
              "assessmentType" => "LAYER_1",
              "status" => "COMPLETE"
            }
          ]
        }.to_json
      end

      before do
        stub_request(:get, stub_url).to_return(status: 200, body: response)
      end

      it 'checks that the API has only been called once' do
        described_class.get_latest_oasys_date(offender_no)
        expect(a_request(:get, stub_url)).to have_been_made.once
      end

      it 'returns the date the assessment was completed for LAYER_1' do
        expect(described_class.get_latest_oasys_date(offender_no)).to match(assessment_type: "LAYER_1", completed: completed_date)
      end
    end

    context 'when there are multiple completed OASys assessments' do
      let(:response) do
        {
          "timeline" => [
            {
              "completedDate" => "2015-12-06T10:53:44",
              "assessmentType" => "LAYER_3",
              "status" => "COMPLETE"
            },
            {
              "completedDate" => "2015-12-05T10:53:44",
              "assessmentType" => "LAYER_1",
              "status" => "COMPLETE"
            },
            {
              "completedDate" => "2015-12-04T10:53:44",
              "assessmentType" => "LAYER_3",
              "status" => "COMPLETE"
            },
            {
              "completedDate" => "2012-12-22T14:20:42",
              "assessmentType" => "LAYER_1",
              "status" => "COMPLETE"
            }
          ]
        }.to_json
      end

      before do
        stub_request(:get, stub_url).to_return(status: 200, body: response)
      end

      it 'returns the most recently completed assessment' do
        expect(described_class.get_latest_oasys_date(offender_no)).to match(
          assessment_type: "LAYER_3", completed: Date.new(2015, 12, 6))
      end
    end

    context 'when there are multiple completed but invalid OASys assessments to ignore' do
      let(:response) do
        {
          "timeline" => [
            {
              "completedDate" => "2015-12-06T10:53:44",
              "assessmentType" => "PORK_CHOPS",
              "status" => "COMPLETE"
            },
            {
              "completedDate" => "2015-12-05T10:53:44",
              "assessmentType" => "MEATBALLS",
              "status" => "COMPLETE"
            },
            {
              "completedDate" => "2015-12-04T10:53:44",
              "assessmentType" => "BACON",
              "status" => "COMPLETE"
            },
            {
              "completedDate" => "2012-12-22T14:20:42",
              "assessmentType" => "SAUSAGES",
              "status" => "COMPLETE"
            }
          ]
        }.to_json
      end

      before do
        stub_request(:get, stub_url).to_return(status: 200, body: response)
      end

      it 'returns nil' do
        expect(described_class.get_latest_oasys_date(offender_no)).to eq(nil)
      end
    end

    context 'when there are no assessments (it returns an empty array)' do
      let(:response) do
        { "timeline" => [] }.to_json
      end

      before do
        stub_request(:get, stub_url).to_return(status: 200, body: response)
      end

      it 'returns nil' do
        expect(described_class.get_latest_oasys_date(offender_no)).to eq(nil)
      end
    end

    context 'when the offender is not found (status 404)' do
      before do
        stub_request(:get, stub_url).to_return(status: 404, body: { "status": 404 }.to_json)
      end

      it 'returns nil' do
        expect(described_class.get_latest_oasys_date(offender_no)).to eq(nil)
      end
    end

    context 'when the offender is duplicated in oasys (status 409)' do
      before do
        stub_request(:get, stub_url).to_return(status: 409, body: {
          "status": 409,
          "developerMessage": "Offender duplicate found for NOMIS, A1857ER"
        }.to_json)
      end

      it 'returns 409 constant' do
        expect(described_class.get_latest_oasys_date(offender_no)).to match(assessment_type: Faraday::ConflictError, completed: nil)
      end
    end

    context 'when assessment API is down (status 500 -) show unavailable message' do
      before do
        stub_request(:get, stub_url).to_return(status: 503, body: {
          "status": 503,
          "developerMessage": "Offender duplicate found for NOMIS, A1857ER"
        }.to_json)
      end

      it 'returns 5xx error code' do
        expect(described_class.get_latest_oasys_date(offender_no)).to match(assessment_type: Faraday::ServerError, completed: nil)
      end
    end
  end
end
