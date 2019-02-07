require 'rails_helper'
feature 'Allocation' do
  let(:pom) { Nomis::Elite2::PrisonOffenderManager.new(staff_id: 485_752) }
  let(:prisoner) { Nomis::Elite2::Offender.new(offender_no: 'G4273GI', tier: 'C', latest_booking_id: '1153753') }

  xscenario 'creating an allocation', vcr: { cassette_name: :create_allocation_feature } do
    signin_user

    visit allocate_new_path(prisoner.offender_no, pom.staff_id)

    expect(page).to have_css('h1', text: 'Confirm allocation')
    expect(page).to have_css('p', text: 'You are allocating Abbella, Ozullirn to Jones, Ross')

    click_button 'Complete allocation'

    expect(page).to have_current_path allocations_path
  end
end
