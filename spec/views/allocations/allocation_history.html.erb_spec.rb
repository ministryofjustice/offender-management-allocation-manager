require 'rails_helper'

RSpec.describe "allocations/history", type: :view do
  let(:dummy_version) { Struct.new(:object_changes).new({ 'updated_at' => [Time.zone.now, Time.zone.now] }.to_yaml) }

  context 'when allocator completes an override against the recommendation (allocation)' do
    before do
      assign(:prisoner, build(:offender))
      assign(:pom_emails, {})
      assign(:history, [
          build(:allocation, override_reasons: ["suitability"], suitability_detail: "Too high risk"),
          build(:allocation, override_reasons: ["suitability"], event: Allocation::REALLOCATE_PRIMARY_POM, suitability_detail: "Continuity")
      ].map { |ah| AllocationHistory.new(ah, dummy_version) })
    end

    let(:page) { Nokogiri::HTML(rendered) }

    it 'shows a reason why in the allocation history' do
      render
      expect(page.css('#override-reason-allocation').text).to include 'Too high risk'
      expect(page.css('#override-reason-reallocation').text).to include 'Continuity'
    end
  end

  # Their is a fix in this view to display incorrect data correctly due to a bug created in the Override Controller. Unfortunately this bad data
  # can not be altered so to get around this it has been modified at the view level.
  context 'when a prisoner has moved to another prison' do
    before do
      assign(:prisoner, build(:offender))
      assign(:pom_emails, {})
      assign(:history, [
          build(:allocation, :primary, prison: prison_one),
          build(:allocation, :transfer, prison: prison_one),
          build(:allocation, :reallocation, :override, prison: prison_two)
      ].map { |ah| AllocationHistory.new(ah, dummy_version) })
    end

    let(:prison_one) { build(:prison).code }
    let(:prison_two) { build(:prison).code }
    let(:page) { Nokogiri::HTML(rendered) }

    it 'displays an allocation label in the allocation history' do
      render
      expect(page.css(".moj-timeline__title").map(&:text).map(&:strip)).to eq ["Prisoner allocated", "Prisoner unallocated", "Prisoner allocated"]
    end
  end

  context 'when a prisoner has been released' do
    before do
      assign(:prisoner, build(:offender))
      assign(:pom_emails, {})
      assign(:history, [build(:allocation, :primary),
                        build(:allocation, :release, updated_at: release_date_and_time)]
                           .map { |ah| AllocationHistory.new(ah, dummy_version) })
    end

    let(:release_date_and_time) { DateTime.new(2019, 8, 19, 11, 28, 0) }
    let(:page) { Nokogiri::HTML(rendered) }

    # Proper test and code fix coming in MO-36
    it 'doesnt crash' do
      render
    end
  end
end
