require 'rails_helper'

RSpec.describe MetricsService do
  it "can increment the search counter" do
    expect(described_class.instance).to receive(:send_value).with('searches', 1, MetricTypes::COUNTER)
    described_class.instance.increment_search_count
  end

  it "can increment the search counter by more than one" do
    expect(described_class.instance).to receive(:send_value).with('searches', 2, MetricTypes::COUNTER)
    described_class.instance.increment_search_count(by: 2)
  end
end
