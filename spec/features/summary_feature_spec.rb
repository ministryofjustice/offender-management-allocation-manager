require 'rails_helper'

feature 'male prisoners summary navigation tabs' do
  before do
    signin_spo_user([prison.code, 'AGI'])
    stub_signin_spo(pom, [prison.code, 'AGI'])
    stub_offenders_for_prison(prison.code, offenders)

    create(:case_information, nomis_offender_id: offender_ready_to_allocate.fetch(:offenderNo))
    create(:case_information, nomis_offender_id: allocated_offender_one.fetch(:offenderNo))
    create(:case_information, nomis_offender_id: allocated_offender_two.fetch(:offenderNo))

    create(:allocation, primary_pom_allocated_at: one_day_ago,  nomis_offender_id: allocated_offender_one.fetch(:offenderNo), prison: prison.code)
    create(:allocation, primary_pom_allocated_at: two_days_ago, nomis_offender_id: allocated_offender_two.fetch(:offenderNo), prison: prison.code)
  end

  let(:pom) { build(:pom) }
  let(:prison) { build :prison }

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
  let(:newly_arrived_offender) { build(:nomis_offender, sentence: attributes_for(:sentence_detail, sentenceStartDate: today)) }

  let(:offenders) {
    [offender_with_missing_info_one,
     offender_with_missing_info_two,
     offender_with_missing_info_three,
     allocated_offender_one,
     allocated_offender_two,
     offender_ready_to_allocate,
     newly_arrived_offender
    ]
  }

  let(:active_tab) {
    page.find('.moj-sub-navigation a[aria-current=page]').text
  }

  it 'shows allocated offenders' do
    visit allocated_prison_prisoners_path(prison.code)
    expect(active_tab).to eq('See allocations (2)')
    expect(page).to have_content('See allocations (2)')
    expect(page).to have_content('Make allocations (1)')
    expect(page).to have_content('Add missing information (3)')
    expect(page).to have_content('Newly arrived (1)')
  end

  it 'shows unallocated offenders' do
    visit unallocated_prison_prisoners_path(prison.code)
    expect(active_tab).to eq('Make allocations (1)')
    expect(page).to have_content('See allocations (2)')
    expect(page).to have_content('Make allocations (1)')
    expect(page).to have_content('Add missing information (3)')
    expect(page).to have_content('Newly arrived (1)')
  end

  it 'shows newly arrived offenders' do
    visit new_arrivals_prison_prisoners_path(prison.code)
    expect(active_tab).to eq('Newly arrived (1)')
    expect(page).to have_content('See allocations (2)')
    expect(page).to have_content('Make allocations (1)')
    expect(page).to have_content('Add missing information (3)')
    expect(page).to have_content('Newly arrived (1)')
  end

  it 'shows offenders with missing information' do
    visit missing_information_prison_prisoners_path(prison.code)
    expect(active_tab).to eq('Add missing information (3)')
    expect(page).to have_content('See allocations (2)')
    expect(page).to have_content('Make allocations (1)')
    expect(page).to have_content('Add missing information (3)')
    expect(page).to have_content('Newly arrived (1)')
  end
end
