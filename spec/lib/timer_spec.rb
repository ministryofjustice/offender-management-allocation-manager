require "rails_helper"

describe Timer do
  describe "elapsed seconds" do
    context "when the timer started 2 minutes ago" do
      it "is 120 seconds" do
        timer = described_class.new(start_time: 2.minutes.ago)
        expect(timer.elapsed_seconds).to be_within(1).of(120)
      end
    end
  end
end
