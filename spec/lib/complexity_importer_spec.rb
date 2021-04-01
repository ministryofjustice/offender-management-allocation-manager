require 'rails_helper'
require 'complexity_importer'

describe ComplexityImporter do
  let(:complexity_data) {
    {
      'T1234RF' => 'high',
      'Y5643IH' => 'low'
    }
  }
  let(:headers) {  { 'NOMS No' => 'Complexity Score Band' } }

  let(:rows) {
    headers.merge(complexity_data).map { |num, level| [num, level] }.map { |row| row.join(',') }.join("\n")
  }

  before do
    stub_auth_token

    complexity_data.each do |num, level|
      stub_request(:post, "https://complexity-of-need-staging.hmpps.service.justice.gov.uk/v1/complexity-of-need/offender-no/#{num}").
        with(
          body: "{\"level\":\"#{level}\",\"sourceUser\":null,\"notes\":null}",
        ).to_return(body: {}.to_json)
    end
  end

  it 'loads data' do
    described_class.import(rows)
  end
end
