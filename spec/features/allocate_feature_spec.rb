require 'rails_helper'

feature 'Allocation' do
  let(:nomis_staff_id) { 485_752 }
  let(:nomis_offender_id) { 'G4273GI' }

  before do
    CaseInformation.create(nomis_offender_id: nomis_offender_id, tier: 'A', case_allocation: 'NPC')
  end

  scenario 'creating an allocation', vcr: { cassette_name: :create_allocation_feature } do
    signin_user

    visit new_allocations_path(nomis_offender_id, nomis_staff_id)

    expect(page).to have_css('h1', text: 'Confirm allocation')
    expect(page).to have_css('p', text: 'You are allocating Abbella, Ozullirn to Jones, Ross')

    click_button 'Complete allocation'

    expect(page).to have_current_path summary_path
  end

  scenario 'overriding an allocation', vcr: { cassette_name: :override_allocation_feature } do
    override_nomis_staff_id = 485_636

    signin_user

    visit allocations_show_path(nomis_offender_id)

    within('.not_recommended_pom_row_0') do
      click_link 'Allocate'
    end

    expect(page).to have_css('h1', text: 'Choose reason for changing recommended grade')

    check('override-1')
    check('override-2')
    click_button('Continue')

    expect(Override.count).to eq(1)
    expect(page).to have_current_path new_allocations_path(nomis_offender_id, override_nomis_staff_id)

    click_button 'Complete allocation'

    expect(page).to have_current_path summary_path
    expect(Override.count).to eq(0)
  end

  scenario 're-allocating', vcr: { cassette_name: :re_allocate_feature } do
    pom_detail = PomDetail.create!(
      nomis_staff_id: nomis_staff_id,
      working_pattern: 1.0,
      status: 'Active'
    )

    pom_detail.allocations.create!(
      nomis_offender_id: nomis_offender_id,
      nomis_booking_id: 1_153_753,
      prison: 'LEI',
      allocated_at_tier: 'A',
      created_by: 'spo@leeds.hmpps.gov.uk',
      active: true
    )

    signin_user

    visit '/summary#allocated'

    within('.allocated_offender_row_0') do
      click_link 'Reallocate'
    end

    expect(page).to have_current_path allocations_show_path(nomis_offender_id)
  end
end
