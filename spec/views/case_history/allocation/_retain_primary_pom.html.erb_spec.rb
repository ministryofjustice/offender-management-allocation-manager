require 'rails_helper'

RSpec.describe 'case_history/allocation/_retain_primary_pom', type: :view do
  let(:page) { Capybara.string(rendered) }

  it 'shows the allocation review and override information without tier or ROSH' do
    allocation = build(:allocation_history, prison: 'LEI', primary_pom_name: 'Smith, Jane', created_at: Time.current,
                                            allocated_at_tier: 'A', allocated_at_rosh: 'HIGH', created_by_name: 'Jones, Alex',
                                            reviewed_recommended_pom_type: 'probation', override_reasons: ['other'].to_json,
                                            override_detail: 'Keep the existing relationship')
    render partial: 'case_history/allocation/retain_primary_pom', locals: { retain_primary_pom: allocation }

    expect(page).to have_text('Current allocation reviewed')
    expect(page).to have_text('Prisoner allocated to Smith, Jane retained.')
    expect(page).to have_text('Jones, Alex')
    expect(page).to have_no_text('allocated instead of recommended')
    expect(page).to have_no_text('Tier:')
    expect(page).to have_no_text('ROSH:')
    expect(page).to have_no_text('Prisoner reallocated')
  end

  it 'renders both saved free-text reasons with the standard override detail styling' do
    allocation = create(:allocation_history, prison: create(:prison).code)
    override = OverrideForm.new(
      override_reasons: %w[suitability other],
      suitability_detail: 'The current POM understands the needs of this prisoner',
      more_detail: 'Keep the established working relationship'
    )
    AllocationService.retain(allocation:, override:, recommended_pom_type: RecommendationService::PROBATION_POM)
    history = AllocationService.history(allocation.reload).last

    render partial: 'case_history/allocation/retain_primary_pom', locals: { retain_primary_pom: history }

    expect(page).to have_css('p.govuk-body', text: 'Reason(s):')
    expect(page).to have_css('.app-override-reasons p.app-override-reason--detail',
                             text: override.suitability_detail)
    expect(page).to have_css('.app-override-reasons p.app-override-reason--detail',
                             text: override.more_detail)
  end

  %w[prison probation].each do |review_recommendation|
    it "uses the snapshotted #{review_recommendation} recommendation instead of the original recommendation" do
      original_recommendation = review_recommendation == 'prison' ? 'probation' : 'prison'
      allocation = build(:allocation_history, primary_pom_name: 'Smith, Jane', created_at: Time.current,
                                              recommended_pom_type: original_recommendation,
                                              reviewed_recommended_pom_type: review_recommendation,
                                              override_reasons: %w[no_staff suitability].to_json)

      render partial: 'case_history/allocation/retain_primary_pom', locals: { retain_primary_pom: allocation }

      expect(page).to have_text("No available #{review_recommendation} POMs")
      expect(page).to have_text("Assessed as not suitable for a #{review_recommendation} POM")
      expect(page).to have_no_text("No available #{original_recommendation} POMs")
      expect(page).to have_no_text('other type')
    end
  end
end
