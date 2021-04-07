require 'rails_helper'
require 'complexity_importer'

describe ComplexityImporter do
  # Example CSV file
  # Note:
  # - All values are in title case - whereas the API expects them downcased
  # - Some values are "Unassessed" - these should be skipped
  let(:example_csv) {
    <<~CSV
      NOMS No,Complexity Score Band
      T1234RF,High
      Y5643IH,Medium
      G9876AL,Low
      O5678TW,Unassessed
    CSV
  }

  # Expect these levels to be sent to the API
  # offender no => complexity level
  let(:expected_api_calls) {
    {
      'T1234RF' => 'high',
      'Y5643IH' => 'medium',
      'G9876AL' => 'low',
    }
  }

  before do
    stub_auth_token

    expected_api_calls.each do |offender_no, level|
      endpoint = "/v1/complexity-of-need/offender-no/#{offender_no}"
      stub_request(:post, Rails.configuration.complexity_api_host + endpoint).
        with(
          body: "{\"level\":\"#{level}\",\"sourceUser\":null,\"notes\":null}",
          ).to_return(body: {}.to_json)
    end
  end

  it 'loads data' do
    described_class.import(example_csv)
  end
end
