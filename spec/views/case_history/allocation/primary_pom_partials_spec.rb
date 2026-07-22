# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'case_history/allocation primary POM partials', type: :view do
  let(:created_at) { Time.zone.local(2026, 5, 5, 14, 30, 0) }

  let(:allocation_class) do
    Struct.new(
      :primary_pom_name,
      :primary_pom_email,
      :allocated_at_tier,
      :allocated_at_rosh,
      :override_reasons,
      :recommended_pom_type,
      :suitability_detail,
      :override_detail,
      :created_at,
      :created_by_name,
      keyword_init: true
    )
  end

  let(:allocation) do
    allocation_class.new(
      primary_pom_name: 'john smith',
      primary_pom_email: 'john.smith@example.com',
      allocated_at_tier: 'A',
      allocated_at_rosh: 'HIGH',
      override_reasons: ['suitability'],
      recommended_pom_type: 'probation',
      suitability_detail: 'Too high risk',
      override_detail: 'Other detail',
      created_at: created_at,
      created_by_name: 'Jane Doe'
    )
  end

  let(:page) { Capybara.string(rendered) }

  context 'when rendering allocate_primary_pom' do
    before do
      render partial: 'case_history/allocation/allocate_primary_pom', locals: { allocate_primary_pom: allocation }
    end

    it 'renders the allocated variant with shared content and override details' do
      expect(page).to have_css('.moj-timeline__title', text: 'Prisoner allocated')
      expect(page).to have_css('.moj-timeline__description', text: 'Prisoner allocated to John Smith')
      expect(page).to have_css('.moj-timeline__description', text: 'john.smith@example.com')
      expect(page).to have_css('.moj-timeline__description', text: 'Tier: A')
      expect(page).to have_css('.moj-timeline__description', text: 'ROSH: High')
      expect(page).to have_css('.moj-timeline__description', text: 'Reason(s):')
      expect(page).to have_css('.moj-timeline__description', text: 'Prison POM allocated instead of recommended probation POM')
      expect(page).to have_css('.app-override-reasons', text: 'Too high risk')
      expect(page).to have_css('.app-override-reason--detail', text: 'Too high risk')
    end
  end

  context 'when rendering reallocate_primary_pom without ROSH or overrides' do
    let(:allocation) do
      allocation_class.new(
        primary_pom_name: 'john smith',
        primary_pom_email: nil,
        allocated_at_tier: 'B',
        allocated_at_rosh: nil,
        override_reasons: [],
        recommended_pom_type: nil,
        suitability_detail: nil,
        override_detail: nil,
        created_at: created_at,
        created_by_name: 'Jane Doe'
      )
    end

    before do
      render partial: 'case_history/allocation/reallocate_primary_pom', locals: { reallocate_primary_pom: allocation }
    end

    it 'renders the reallocated variant and omits optional sections' do
      expect(page).to have_css('.moj-timeline__title', text: 'Prisoner reallocated')
      expect(page).to have_css('.moj-timeline__description', text: 'Prisoner reallocated to John Smith')
      expect(page).to have_css('.moj-timeline__description', text: '(email address not found)')
      expect(page).to have_css('.moj-timeline__description', text: 'Tier: B')
      expect(page).to have_css('.moj-timeline__description', text: 'ROSH: N/A')
      expect(page).not_to have_css('.app-override-reasons')
    end
  end
end
