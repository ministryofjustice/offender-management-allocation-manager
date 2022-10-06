RSpec.describe Handover::HandoverDateRules do
  it 'is tested with Cucumber features because non-technical stakeholders must understand the test cases' do
    expect(File.exist?(Rails.root.join('features/handover/handover_date_rules.feature'))).to eq true
  end
end
