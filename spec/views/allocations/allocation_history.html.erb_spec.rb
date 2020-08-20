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
end
