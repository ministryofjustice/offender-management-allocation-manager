require 'rails_helper'

feature 'male prisoners summary navigation tabs' do
  before do
    signin_spo_user([prison.code, 'AGI'])
    stub_signin_spo(pom, [prison.code, 'AGI'])
    stub_offenders_for_prison(prison.code, offenders)
    stub_bank_holidays

    create(:case_information, offender: build(:offender, nomis_offender_id: offender_ready_to_allocate.fetch(:prisonerNumber)))
    create(:case_information, offender: build(:offender, nomis_offender_id: allocated_offender_one.fetch(:prisonerNumber)))
    create(:case_information, offender: build(:offender, nomis_offender_id: allocated_offender_two.fetch(:prisonerNumber)))

    create(:allocation_history, primary_pom_allocated_at: one_day_ago,  nomis_offender_id: allocated_offender_one.fetch(:prisonerNumber), prison: prison.code)
    create(:allocation_history, primary_pom_allocated_at: two_days_ago, nomis_offender_id: allocated_offender_two.fetch(:prisonerNumber), prison: prison.code)
  end

  let(:pom) { build(:pom) }
  let(:prison) { create(:prison) }

  let(:today) { Time.zone.today }
  let(:one_day_ago) { Time.zone.today - 1.day }
  let(:two_days_ago) { Time.zone.today - 2.days }
  let(:three_days_ago) { Time.zone.today - 3.days }

  let(:offender_with_missing_info_one) { build(:nomis_offender, sentence: attributes_for(:sentence_detail, sentenceStartDate: three_days_ago), lastName: 'Austin') }
  let(:offender_with_missing_info_two) { build(:nomis_offender, sentence: attributes_for(:sentence_detail, sentenceStartDate: one_day_ago), lastName: 'Blackburn') }
  let(:offender_with_missing_info_three) { build(:nomis_offender, sentence: attributes_for(:sentence_detail, sentenceStartDate: two_days_ago), lastName: 'Carsley') }
  let(:allocated_offender_one) { build(:nomis_offender) }
  let(:allocated_offender_two) { build(:nomis_offender) }
  let(:offender_ready_to_allocate) { build(:nomis_offender) }

  let(:offenders) do
    [offender_with_missing_info_one,
     offender_with_missing_info_two,
     offender_with_missing_info_three,
     allocated_offender_one,
     allocated_offender_two,
     offender_ready_to_allocate,
    ]
  end

  let(:active_tab) do
    page.find('.moj-sub-navigation a[aria-current=page]').text
  end

  it 'shows allocated offenders' do
    visit allocated_prison_prisoners_path(prison.code)
    expect(active_tab).to eq('See allocations (2)')
    expect(page).to have_content('See allocations (2)')
    expect(page).to have_content('Make allocations (1)')
    expect(page).to have_content('Add missing details (3)')
  end

  it 'shows unallocated offenders' do
    visit unallocated_prison_prisoners_path(prison.code)
    expect(active_tab).to eq('Make allocations (1)')
    expect(page).to have_content('See allocations (2)')
    expect(page).to have_content('Make allocations (1)')
    expect(page).to have_content('Add missing details (3)')
  end

  it 'shows offenders with missing information' do
    visit missing_information_prison_prisoners_path(prison.code)
    expect(active_tab).to eq('Add missing details (3)')
    expect(page).to have_content('See allocations (2)')
    expect(page).to have_content('Make allocations (1)')
    expect(page).to have_content('Add missing details (3)')
  end
end
