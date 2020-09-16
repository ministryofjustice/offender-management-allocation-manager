require 'rails_helper'

RSpec.describe "allocations/history", type: :view do
  context 'when allocator completes an override against the recommendation (allocation)' do
    before do
      assign(:prisoner, build(:offender))
      assign(:pom_emails, {})
      assign(:history, [build(:allocation, override_reasons: ["suitability"], suitability_detail: "Too high risk"),
                        build(:allocation, override_reasons: ["suitability"], event: Allocation::REALLOCATE_PRIMARY_POM, suitability_detail: "Continuity")])
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
      assign(:history, [build(:allocation, :primary, prison: prison_one),
                        build(:allocation, :transfer, prison: prison_one),
                        build(:allocation, :reallocation, :override, prison: prison_two)])
    end

    let(:prison_one) { build(:prison).code }
    let(:prison_two) { build(:prison).code }
    let(:page) { Nokogiri::HTML(rendered) }

    it 'displays an allocation label in the allocation history' do
      render
      expect(page.css(".moj-timeline__title").map(&:text).map(&:strip)).to eq ["Prisoner allocated", "Prisoner unallocated", "Prisoner allocated"]
    end
  end
end
