require 'rails_helper'

RSpec.describe SignificantChanges::RoshDetector do
  include_context 'with a significant changes detector'

  before do
    allow(offender).to receive(:recommended_pom_type).and_return(RecommendationService::PROBATION_POM)
  end

  [%w[MEDIUM HIGH], %w[LOW VERY_HIGH], %w[HIGH LOW], %w[VERY_HIGH MEDIUM]].each do |from, to|
    it "flags a change from #{from} to #{to}" do
      expect(detect(case_info_version({ 'rosh_level' => [from, to] })))
        .to have_attributes(type: :rosh, label: 'ROSH', from_value: from, to_value: to)
    end
  end

  [%w[LOW MEDIUM], %w[HIGH VERY_HIGH]].each do |from, to|
    it "does not flag a change from #{from} to #{to}" do
      expect(detect(case_info_version({ 'rosh_level' => [from, to] }))).to be_nil
    end
  end

  it 'does not flag a ROSH change when the allocated POM already matches the recommendation' do
    allow(review).to receive(:allocated_pom_position).and_return(RecommendationService::PROBATION_POM)

    expect(detect(case_info_version({ 'rosh_level' => %w[MEDIUM HIGH] }))).to be_nil
  end
end
