require 'rails_helper'

RSpec.describe SignificantChanges::Detector do
  include_context 'with a significant changes detector'

  before do
    allow(offender).to receive(:recommended_pom_type).and_return(RecommendationService::PROBATION_POM)
  end

  let(:detector_class) do
    Class.new(described_class) do
      tracks :colour, label: 'Colour', item_type: 'CaseInformation', attribute: 'colour'

      attr_accessor :significant

    private

      def band(colour) = { 'red' => :warm, 'orange' => :warm, 'blue' => :cold }[colour]
      def significant?(_change) = significant.nil? || significant
    end
  end

  def detect(*versions, significant: nil)
    detector_class.new(review, versions).tap { it.significant = significant }.change
  end

  it 'returns a change when the band differs' do
    change = detect(case_info_version({ 'colour' => %w[blue red] }))

    expect(change).to have_attributes(type: :colour, label: 'Colour', from_value: 'blue', to_value: 'red', changed_at:)
  end

  it 'returns nothing when there are no versions' do
    expect(detect).to be_nil
  end

  it 'returns nothing when the value stays in the same band' do
    expect(detect(case_info_version({ 'colour' => %w[red orange] }))).to be_nil
  end

  it 'returns nothing when either value is irrelevant' do
    aggregate_failures do
      expect(detect(case_info_version({ 'colour' => [nil, 'red'] }))).to be_nil
      expect(detect(case_info_version({ 'colour' => %w[red green] }))).to be_nil
    end
  end

  it 'ignores versions for other attributes and item types' do
    aggregate_failures do
      expect(detect(case_info_version({ 'tier' => %w[B A] }))).to be_nil
      expect(detect(version('AllocationHistory', { 'colour' => %w[blue red] }))).to be_nil
    end
  end

  it 'compares the first value with the latest value' do
    change = detect(case_info_version({ 'colour' => %w[blue green] }, changed_at),
                    case_info_version({ 'colour' => %w[green red] }, changed_at + 1.day))

    expect(change).to have_attributes(from_value: 'blue', to_value: 'red')
  end

  it 'returns nothing when a change has since been reverted' do
    expect(detect(case_info_version({ 'colour' => %w[blue red] }, changed_at),
                  case_info_version({ 'colour' => %w[red blue] }, changed_at + 1.day))).to be_nil
  end

  it 'dates the change from the start of the current run of values in the same band' do
    change = detect(case_info_version({ 'colour' => %w[blue red] }, changed_at),
                    case_info_version({ 'colour' => %w[red blue] }, changed_at + 1.day),
                    case_info_version({ 'colour' => %w[blue red] }, changed_at + 2.days),
                    case_info_version({ 'colour' => %w[red orange] }, changed_at + 3.days))

    expect(change.changed_at).to eq(changed_at + 2.days)
  end

  it 'returns nothing when the subclass decides the change is not significant' do
    expect(detect(case_info_version({ 'colour' => %w[blue red] }), significant: false)).to be_nil
  end
end
