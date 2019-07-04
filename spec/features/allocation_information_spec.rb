# frozen_string_literal: true

require "rails_helper"

feature "view an offender's allocation information" do
  let!(:probation_officer_nomis_staff_id) { 485_636 }
  let!(:nomis_offender_id_with_keyworker) { 'G4273GI' }
  let!(:nomis_offender_id_without_keyworker) { 'G9403UP' }
  let!(:allocated_at_tier) { 'A' }
  let!(:prison) { 'LEI' }
  let!(:pom_detail) {
    PomDetail.create!(
      nomis_staff_id: probation_officer_nomis_staff_id,
      working_pattern: 1.0,
      status: 'Active'
    )
  }

  describe 'Offender has a key worker assigned', vcr: { cassette_name: :show_allocation_information_keyworker_assigned } do
    before do
      create_case_information_for(nomis_offender_id_with_keyworker)
      create_allocation(nomis_offender_id_with_keyworker)
    end

    it "displays the Key Worker's details" do
      signin_user

      visit prison_allocation_path('LEI', nomis_offender_id: nomis_offender_id_with_keyworker)

      expect(page).to have_css('h1', text: 'Allocation information')

      # Prisoner
      expect(page).to have_css('.govuk-table__cell', text: 'Abbella, Ozullirn')
      # Pom
      expect(page).to have_css('.govuk-table__cell', text: 'Duckett, Jenny')
      # Keyworker
      expect(page).to have_css('.govuk-table__cell', text: 'Bull, Dom')
    end
  end

  describe 'Offender does not have a key worker assigned', :raven_intercept_exception,
           vcr: { cassette_name: :show_allocation_information_keyworker_not_assigned } do
    before do
      create_case_information_for(nomis_offender_id_without_keyworker)
      create_allocation(nomis_offender_id_without_keyworker)
    end

    it "displays 'Data not available'" do
      signin_user

      visit prison_allocation_path('LEI', nomis_offender_id: nomis_offender_id_without_keyworker)

      expect(page).to have_css('h1', text: 'Allocation information')

      # Prisoner
      expect(page).to have_css('.govuk-table__cell', text: 'Albina, Obinins')
      # Pom
      expect(page).to have_css('.govuk-table__cell', text: 'Duckett, Jenny')
      # Keyworker
      expect(page).to have_css('.govuk-table__cell', text: 'Data not available')
    end
  end

  describe 'Prisoner profile links', vcr: { cassette_name: :show_allocation_information_new_nomis_profile } do
    before do
      create_case_information_for(nomis_offender_id_with_keyworker)
      create_allocation(nomis_offender_id_with_keyworker)
    end

    it "displays a link to the prisoner's New Nomis profile" do
      signin_user

      visit prison_allocation_path('LEI', nomis_offender_id: nomis_offender_id_with_keyworker)

      expect(page).to have_css('.govuk-table__cell', text: 'View NOMIS profile')
      expect(find_link('View NOMIS profile')[:target]).to eq('_blank')
      expect(find_link('View NOMIS profile')[:href]).to include('offenders/G4273GI/quick-look')
    end
  end

  def create_case_information_for(offender_no)
    CaseInformation.create!(
      nomis_offender_id: offender_no,
      tier: 'A',
      case_allocation: 'NPS',
      omicable: 'No',
      prison: prison
    )
  end

  def create_allocation(offender_no)
    create(
      :allocation_version,
      nomis_offender_id: offender_no,
      primary_pom_nomis_id: probation_officer_nomis_staff_id,
      prison: prison,
      allocated_at_tier: allocated_at_tier
    )
  end
end
