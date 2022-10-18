RSpec.describe Handover::HandoverDateRules do
  it 'is tested with Cucumber features because non-technical stakeholders must understand the test cases' do
    expect(Dir.glob(Rails.root.join('features/handover/handover_date_rules/*.feature')).count).to be > 0
  end
end
