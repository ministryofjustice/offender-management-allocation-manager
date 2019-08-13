# frozen_string_literal: true

require "rails_helper"

feature "view an offender's allocation information" do
  let!(:probation_officer_nomis_staff_id) { 485_636 }
  let!(:nomis_offender_id_with_keyworker) { 'G4273GI' }
  let!(:nomis_offender_id_without_keyworker) { 'G9403UP' }
  let!(:allocated_at_tier) { 'A' }
  let!(:prison) { 'LEI' }
  let!(:recommended_pom_type) { 'probation' }
  let!(:pom_detail) {
    PomDetail.create!(
      nomis_staff_id: probation_officer_nomis_staff_id,
      working_pattern: 1.0,
      status: 'Active'
    )
  }

  before do
    signin_user
  end

  describe 'Offender does not have a key worker assigned' do
    before do
      create_case_information_for(nomis_offender_id_without_keyworker)
      create_allocation(nomis_offender_id_without_keyworker)
    end

    it "displays 'Data not available'", :raven_intercept_exception,
       vcr: { cassette_name: :show_allocation_information_keyworker_not_assigned } do
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

  context 'when Offender has a key worker assigned' do
    before do
      create_case_information_for(nomis_offender_id_with_keyworker)
      create_allocation(nomis_offender_id_with_keyworker)
      visit prison_allocation_path('LEI', nomis_offender_id: nomis_offender_id_with_keyworker)
    end

    it "displays the Key Worker's details", vcr: { cassette_name: :show_allocation_information_keyworker_assigned } do
      expect(page).to have_css('h1', text: 'Allocation information')

      # Prisoner
      expect(page).to have_css('.govuk-table__cell', text: 'Abbella, Ozullirn')
      # Pom
      expect(page).to have_css('.govuk-table__cell', text: 'Duckett, Jenny')
      # Keyworker
      expect(page).to have_css('.govuk-table__cell', text: 'Bull, Dom')
    end

    it "displays a link to the prisoner's New Nomis profile", vcr: { cassette_name: :show_allocation_information_new_nomis_profile } do
      expect(page).to have_css('.govuk-table__cell', text: 'View NOMIS profile')
      expect(find_link('View NOMIS profile')[:target]).to eq('_blank')
      expect(find_link('View NOMIS profile')[:href]).to include('offenders/G4273GI/quick-look')
    end

    it 'displays a link to allocate a co-worker', vcr: { cassette_name: :show_allocation_information_display_coworker_link } do
      table_row = page.find(:css, 'tr.govuk-table__row', text: 'Co-working POM')

      within table_row do
        expect(page).to have_link('Allocate',
                                  href: new_prison_coworking_path('LEI', nomis_offender_id_with_keyworker))
        expect(page).to have_content('Co-working POM N/A')
      end
    end

    it 'displays the name of the allocated co-worker', vcr: { cassette_name: :show_allocation_information_display_coworker_name } do
      allocation = AllocationVersion.find_by(nomis_offender_id: nomis_offender_id_with_keyworker)

      allocation.update!(event: AllocationVersion::ALLOCATE_SECONDARY_POM,
                         secondary_pom_nomis_id: 485_752,
                         secondary_pom_name: "Ross Jones")

      visit prison_allocation_path('LEI', nomis_offender_id: nomis_offender_id_with_keyworker)

      table_row = page.find(:css, 'tr.govuk-table__row#co-working-pom', text: 'Co-working POM')

      within table_row do
        expect(page).to have_link('Remove')
        expect(page).to have_content('Co-working POM Jones, Ross')
      end
    end

    it 'displays a link to the allocation history', vcr: { cassette_name: :show_allocation_information_history_link } do
      table_row = page.find(:css, 'tr.govuk-table__row', text: 'Allocation history')

      within table_row do
        expect(page).to have_link('View')
        expect(page).to have_content("POM allocated - #{Time.zone.now.strftime('%d/%m/%Y')}")
      end
    end

    context 'without auto_delius_import enabled' do
      it 'does display change links' do
        expect(page).to have_content 'Change'
      end
    end

    context 'with auto_delius_import enabled' do
      let(:test_strategy) { Flipflop::FeatureSet.current.test! }

      before do
        test_strategy.switch!(:auto_delius_import, true)
      end

      after do
        test_strategy.switch!(:auto_delius_import, false)
      end

      it 'does not display change links' do
        visit prison_allocation_path('LEI', nomis_offender_id: nomis_offender_id_with_keyworker)

        expect(page).not_to have_content 'Change'
      end
    end
  end

  def create_case_information_for(offender_no)
    create(:case_information,
           nomis_offender_id: offender_no,
           tier: 'A',
           case_allocation: 'NPS',
           omicable: 'No'
    )
  end

  def create_allocation(offender_no)
    create(
      :allocation_version,
      nomis_offender_id: offender_no,
      primary_pom_nomis_id: probation_officer_nomis_staff_id,
      prison: prison,
      allocated_at_tier: allocated_at_tier,
      recommended_pom_type: recommended_pom_type
    )
  end
end
