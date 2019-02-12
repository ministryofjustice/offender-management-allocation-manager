require 'rails_helper'

feature 'Allocation' do
  let(:nomis_staff_id) { 485752 }
  let(:nomis_offender_id) { 'G4273GI' }

  scenario 'creating an allocation', vcr: { cassette_name: :create_allocation_feature } do
    signin_user

    visit new_allocates_path(nomis_offender_id, nomis_staff_id)

    expect(page).to have_css('h1', text: 'Confirm allocation')
    expect(page).to have_css('p', text: 'You are allocating Abbella, Ozullirn to Jones, Ross')

    click_button 'Complete allocation'

    expect(page).to have_current_path allocations_path
  end

  scenario 'overriding an allocation', vcr: { cassette_name: :override_allocation_feature } do
    override_nomis_staff_id = 485636

    signin_user

    visit allocates_show_path(nomis_offender_id)

    within('.not_recommended_pom_row_0') do
      click_link 'Allocate'
    end

    expect(page).to have_css('h1', text: 'Choose reason for changing recommended grade')

    check('override-1')
    click_button('Continue')

    expect(Override.count).to eq(1)
    expect(page).to have_current_path new_allocates_path(nomis_offender_id, override_nomis_staff_id)

    click_button 'Complete allocation'

    expect(page).to have_current_path allocations_path
    expect(Override.count).to eq(0)
  end
end
