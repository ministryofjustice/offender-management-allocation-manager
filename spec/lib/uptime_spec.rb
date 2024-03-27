require "rails_helper"

describe Uptime do
  context "when the application booted 2 minutes ago" do
    it "is 120 seconds of uptime" do
      Timecop.travel(2.minutes.ago)
      described_class.application_did_boot!
      Timecop.return
      expect(described_class.duration_in_seconds).to be_within(1).of(120)
    end
  end
end
