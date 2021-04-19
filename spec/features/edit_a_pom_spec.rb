# frozen_string_literal: true

require "rails_helper"

feature "edit a POM's details" do
  let(:nomis_staff_id) { 485_637 }
  let(:fulltime_pom_id) { 485_833 }
  let(:nomis_offender_id) { 'G4273GI' }

  before do
    create(:case_information, nomis_offender_id: nomis_offender_id)

    create(:pom_detail, prison_code: 'LEI', nomis_staff_id: fulltime_pom_id, working_pattern: 1)

    signin_spo_user
  end

  it "setting unavailable shows selected on re-edit", vcr: { cassette_name: 'prison_api/edit_poms_unavailable_check' } do
    visit edit_prison_pom_path('LEI', nomis_staff_id)
    expect(page).to have_css('h1', text: 'Edit profile')

    choose('working_pattern-2')
    choose('Active but unavailable for new cases')
    click_on('Save')

    visit edit_prison_pom_path('LEI', nomis_staff_id)
    expect(page).to have_css('h1', text: 'Edit profile')

    expect(page).to have_field('status-conditional-2', checked: true)
  end

  it "validates a POM when missing data", vcr: { cassette_name: 'prison_api/edit_poms_missing_check' } do
    visit edit_prison_pom_path('LEI', fulltime_pom_id)
    expect(page).to have_css('h1', text: 'Edit profile')

    expect(page.find('#working_pattern-ft')).to be_checked

    # The only way to trigger (and therefore cover) the validation is for a full-time POM
    # to be edited to part time but not choose a working pattern.
    choose('part-time-conditional-1')
    click_on('Save')

    expect(page).to have_css('h1', text: 'Edit profile')
    expect(page).to have_content('Select number of days worked')
  end

  it "makes an inactive POM active", vcr: { cassette_name: 'prison_api/edit_poms_activate_pom_feature' } do
    # This doesn't do what it appears to - the URL is wrong so we're not editing an inactive POM... :-(
    visit "/prisons/LEI/poms#inactive"
    click_link 'Moic Integration-Tests'

    click_link "Edit profile"

    expect(page).to have_css('h1', text: 'Edit profile')

    find('label[for=working_pattern-5]').click
    find('label[for=status-1]').click

    click_button('Save')

    expect(page).to have_content('0.5')
    expect(page).to have_content('Active')
  end

  context 'when a POM is made inactive' do
    before do
      # create an allocation with the POM as the primary POM
      create(
        :allocation,
        nomis_offender_id: 'G7806VO',
        primary_pom_nomis_id: 485_926,
        prison: 'LEI'
      )

      # create an allocation with the POM as the co-working POM
      create(
        :allocation,
        nomis_offender_id: 'G1670VU',
        primary_pom_nomis_id: 485_833,
        secondary_pom_nomis_id: 485_926,
        prison: 'LEI'
          )
    end

    it "de-allocates all a POM's cases", vcr: { cassette_name: 'prison_api/edit_poms_deactivate_pom_feature' } do
      visit "/prisons/LEI/poms/485926"
      click_link "Edit profile"

      expect(page).to have_content("Moic Pom")
      expect(Allocation.count).to eq 2

      choose('working_pattern-2')
      choose('Inactive')
      click_button('Save')

      expect(page).to have_content("Pom, Moic")
      expect(page).to have_css('.pom_cases_row_0', count: 0)
    end
  end
end
