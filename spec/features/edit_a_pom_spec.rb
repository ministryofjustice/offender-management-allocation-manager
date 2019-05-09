require "rails_helper"

feature "edit a POM's details" do
  let(:nomis_staff_id) { 485_637 }
  let(:fulltime_pom_id) { 485_737 }
  let(:nomis_offender_id) { 'G4273GI' }

  before do
    CaseInformation.create(nomis_offender_id: nomis_offender_id, tier: 'A', case_allocation: 'NPC', omicable: 'Yes', prison: 'LEI')
  end

  it "setting unavailable shows selected on re-edit", vcr: { cassette_name: :edit_poms_unavailable_check } do
    signin_user

    visit edit_pom_path(nomis_staff_id)
    expect(page).to have_css('h1', text: 'Edit profile')

    choose('working_pattern-2')
    choose('Active but unavailable for new cases')
    click_on('Save')

    visit edit_pom_path(nomis_staff_id)
    expect(page).to have_css('h1', text: 'Edit profile')

    expect(page).to have_field('status-conditional-2', checked: true)
  end

  it "validates a POM when missing data", vcr: { cassette_name: :edit_poms_unavailable_check } do
    signin_user

    visit edit_pom_path(fulltime_pom_id)
    expect(page).to have_css('h1', text: 'Edit profile')

    # The only way to trigger (and therefore cover) the validation is for a full-time POM
    # to be edited to part time but not choose a working pattern.
    choose('part-time-conditional-1')
    click_on('Save')

    expect(page).to have_css('h1', text: 'Edit profile')
    expect(page).to have_content('Select number of days worked')
  end

  it "makes an inactive POM active", vcr: { cassette_name: :edit_poms_activate_pom_feature } do
    signin_user

    visit "/poms#inactive"
    within('.probation_pom_row_0') do
      click_link 'View'
    end

    click_link "Edit profile"

    expect(page).to have_css('h1', text: 'Edit profile')

    choose('working_pattern-5')
    choose('status-1')

    click_button('Save')

    expect(page).to have_content('0.5')
    expect(page).to have_content('Active')
  end

  it "de-allocates all a POM's cases when made inactive", vcr: { cassette_name: :edit_poms_deactivate_pom_feature } do
    signin_user('PK000223')
    visit "allocations/confirm/G4273GI/485637"
    click_button 'Complete allocation'

    visit "/poms/485637"
    click_link "Edit profile"

    expect(page).to have_content("Kath Pobee Norris")
    expect(AllocationVersion.count).to eq 1

    choose('working_pattern-2')
    choose('Inactive')
    click_button('Save')

    expect(page).to have_content("Pobee Norris, Kath")
    expect(page).to have_css('.pom_cases_row_0', count: 0)
  end
end
