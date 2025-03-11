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
      }

      stub_request(:get, "#{Rails.configuration.prison_alerts_api_host}/prisoners/ABC123/alerts")
        .to_return(body: response.to_json)

      expect(described_class.alerts_for("ABC123")).to eq(response.deep_stringify_keys)
    end
  end
end
