require 'rails_helper'

RSpec.describe SignificantChanges::TierDetector do
  include_context 'with a significant changes detector'

  before do
    allow(offender).to receive(:recommended_pom_type).and_return(RecommendationService::PROBATION_POM)
  end

  it 'flags a change from another tier to A' do
    expect(detect(case_info_version({ 'tier' => %w[C A] })))
      .to have_attributes(type: :tier, label: 'Tier', from_value: 'C', to_value: 'A')
  end

  it 'flags a change from A to another tier' do
    expect(detect(case_info_version({ 'tier' => %w[A D] }))).to have_attributes(from_value: 'A', to_value: 'D')
  end

  it 'does not flag changes between tiers other than A' do
    expect(detect(case_info_version({ 'tier' => %w[B C] }))).to be_nil
  end

  it 'does not flag a tier being set for the first time' do
    expect(detect(case_info_version({ 'tier' => [nil, 'A'] }))).to be_nil
  end

  it 'does not flag a tier change when the allocated POM already matches the recommendation' do
    allow(review).to receive(:allocated_pom_position).and_return(RecommendationService::PROBATION_POM)

    expect(detect(case_info_version({ 'tier' => %w[C A] }))).to be_nil
  end
end
