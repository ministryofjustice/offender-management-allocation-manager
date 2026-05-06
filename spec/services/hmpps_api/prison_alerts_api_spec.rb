require "rails_helper"

describe HmppsApi::PrisonAlertsApi do
  describe ".alerts_for" do
    it "returns alert data for the given offender id" do
      response = {
        content: [
          { "alertCode" => { code: "ABC", description: "ABC Desc" } },
          { "alertCode" => { code: "DEF", description: "DEF Desc" } },
          { "alertCode" => { code: "GHI", description: "GHI Desc" } },
        ]
      }.deep_stringify_keys

      stub_request(:get, "#{Rails.configuration.prison_alerts_api_host}/prisoners/ABC123/alerts")
        .to_return(body: response.to_json)

      expect(described_class.alerts_for("ABC123")).to eq(response["content"])
    end

    context 'when the alerts API is unavailable' do
      it 'returns nil' do
        stub_request(:get, "#{Rails.configuration.prison_alerts_api_host}/prisoners/ABC123/alerts")
          .to_return(status: 503, body: { status: 503 }.to_json)

        expect(described_class.alerts_for('ABC123')).to be_nil
      end
    end

    context 'when the alerts API returns no content' do
      it 'returns nil' do
        stub_request(:get, "#{Rails.configuration.prison_alerts_api_host}/prisoners/ABC123/alerts")
          .to_return(status: 204, body: '')

        expect(described_class.alerts_for('ABC123')).to be_nil
      end
    end

    context 'when the alerts API returns malformed data' do
      it 'returns nil' do
        stub_request(:get, "#{Rails.configuration.prison_alerts_api_host}/prisoners/ABC123/alerts")
          .to_return(body: 'not json')

        expect(described_class.alerts_for('ABC123')).to be_nil
      end
    end
  end
end
