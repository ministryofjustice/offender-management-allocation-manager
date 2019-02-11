require 'rails_helper'
feature 'Allocation' do
  let(:pom) { Nomis::Elite2::PrisonOffenderManager.new(staff_id: 485_752) }
  let(:prisoner) { Nomis::Elite2::Offender.new(offender_no: 'G4273GI', tier: 'C', latest_booking_id: '1153753') }

  scenario 'creating an allocation', vcr: { cassette_name: :create_allocation_feature } do
    signin_user

    visit new_allocates_path(prisoner.offender_no, pom.staff_id)

    expect(page).to have_css('h1', text: 'Confirm allocation')
    expect(page).to have_css('p', text: 'You are allocating Abbella, Ozullirn to Jones, Ross')

    click_button 'Complete allocation'

    expect(page).to have_current_path allocations_path
  end

  scenario 'overriding an allocation', vcr: { cassette_name: :override_allocation_feature } do
    signin_user

    visit allocates_show_path(prisoner.offender_no)

    within('.not_recommended_pom_row_0') do
      click_link 'Allocate'
    end

    expect(page).to have_css('h1', text: 'Choose reason for changing recommended grade')
    check('override-1')

    click_button('Continue')

    expect(page).to have_css('h1', text: 'Confirm allocation')
    expect(page).to have_css('p', text: 'You are allocating Abbella, Ozullirn to Duckett, Jenny')
  end
end
