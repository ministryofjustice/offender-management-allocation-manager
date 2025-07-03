# frozen_string_literal: true

require "rails_helper"

feature "female prison index page" do
  before do
    stub_signin_spo(pom, [prison.code])
    stub_offenders_for_prison(prison.code, offenders)
    stub_bank_holidays

    create(:case_information, offender: build(:offender, nomis_offender_id: allocated_offender_one.fetch(:prisonerNumber)))
    create(:allocation_history, primary_pom_allocated_at: one_day_ago,  nomis_offender_id: allocated_offender_one.fetch(:prisonerNumber), prison: prison.code)
    create(:case_information, offender: build(:offender, nomis_offender_id: allocated_offender_two.fetch(:prisonerNumber)))
    create(:allocation_history, primary_pom_allocated_at: two_days_ago, nomis_offender_id: allocated_offender_two.fetch(:prisonerNumber), prison: prison.code)
    create(:case_information, offender: build(:offender, nomis_offender_id: offender_ready_to_allocate.fetch(:prisonerNumber)))
  end

  let(:pom) { build(:pom) }
  let(:prison) { create :womens_prison }

  let(:one_day_ago) { Time.zone.today - 1.day }
  let(:two_days_ago) { Time.zone.today - 2.days }
  let(:three_days_ago) { Time.zone.today - 3.days }

  let(:offender_with_missing_info_one) { build(:nomis_offender, sentence: attributes_for(:sentence_detail, sentenceStartDate: three_days_ago), lastName: 'Austin') }
  let(:offender_with_missing_info_two) { build(:nomis_offender, sentence: attributes_for(:sentence_detail, sentenceStartDate: one_day_ago), lastName: 'Blackburn') }
  let(:offender_with_missing_info_three) { build(:nomis_offender, sentence: attributes_for(:sentence_detail, sentenceStartDate: two_days_ago), lastName: 'Carsley') }
  let(:allocated_offender_one) { build(:nomis_offender) }
  let(:allocated_offender_two) { build(:nomis_offender) }
  let(:offender_ready_to_allocate) { build(:nomis_offender, complexityLevel: 'medium') }

  let(:offenders) do
    [offender_with_missing_info_one,
     offender_with_missing_info_two,
     offender_with_missing_info_three,
     allocated_offender_one,
     allocated_offender_two,
     offender_ready_to_allocate,
    ]
  end

  describe 'missing details page' do
    before do
      visit missing_information_prison_prisoners_path(prison.code)
    end

    it 'displays offenders with missing details' do
      expect(page).to have_css('.moj-sub-navigation__item')
      expect(page).to have_content('Add missing details')
      expect(page).to have_text("You need to add missing details to 3 cases so they can be allocated to a POM")
    end

    it 'sorts offenders by name' do
      # defaults to ascending order
      expect(page).to have_css('.offender_row_0', text: 'Austin')
      expect(page).to have_css('.offender_row_2', text: 'Carsley')

      click_link('Case')
      # sorts by descending order
      expect(page).to have_css('.offender_row_0', text: 'Carsley')
      expect(page).to have_css('.offender_row_2', text: 'Austin')
    end

    it 'sorts offenders by days waiting for allocation' do
      click_link('Days waiting for allocation')
      # sorts by ascending order
      expect(page).to have_css('.offender_row_0', text: '1 days')
      expect(page).to have_css('.offender_row_1', text: '2 days')
      expect(page).to have_css('.offender_row_2', text: '3 days')

      click_link('Days waiting for allocation')
      # sorts by ascending order
      expect(page).to have_css('.offender_row_0', text: '3 days')
      expect(page).to have_css('.offender_row_1', text: '2 days')
      expect(page).to have_css('.offender_row_2', text: '1 days')
    end

    # the view compatable with female controller. Then make the summary controller make it produce the same variables.
    it 'shows allocated offenders' do
      click_link('See allocations (2)')
      expect(page).to have_css("h1", text: "Allocations")
    end

    it 'shows unallocated offenders' do
      click_link('Make allocations (1)')
      expect(page).to have_css("h1", text: "Allocations")
    end

    it 'shows offenders with missing information' do
      click_link('Add missing details (3)')
      expect(page).to have_content("Add missing details")
    end
  end
end
