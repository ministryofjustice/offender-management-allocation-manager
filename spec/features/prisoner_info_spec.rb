require 'rails_helper'

feature 'View a prisoner profile page' do
  before do
    signin_user
  end

  context 'without allocation' do
    it 'doesnt crash', vcr: { cassette_name: :show_unallocated_offender } do
      visit prison_prisoner_path('LEI', 'G7998GJ')

      expect(page).to have_css('h2', text: 'Ahmonis, Okadonah')
      expect(page).to have_content('07/07/1968')
      cat_code = find('h3#category-code').text
      expect(cat_code).to eq('C')
    end
  end

  context 'with an allocation' do
    let!(:alloc) {
      create(:allocation, nomis_offender_id: 'G7998GJ', primary_pom_nomis_id: '485637')
    }

    it 'shows the prisoner information', :raven_intercept_exception, vcr: { cassette_name: :show_offender_spec } do
      visit prison_prisoner_path('LEI', 'G7998GJ')

      expect(page).to have_css('h2', text: 'Ahmonis, Okadonah')
      expect(page).to have_content('07/07/1968')
      cat_code = find('h3#category-code').text
      expect(cat_code).to eq('C')
    end

    it 'shows an overridden responsibility', :raven_intercept_exception, vcr: { cassette_name: :show_offender_with_override_spec } do
      create(:responsibility, nomis_offender_id: 'G7998GJ')
      visit prison_prisoner_path('LEI', 'G7998GJ')

      expect(page).to have_content('Supporting')
    end

    it 'shows the prisoner image', :raven_intercept_exception, vcr: { cassette_name: :show_offender_spec_image } do
      visit prison_prisoner_image_path('LEI', 'G7998GJ', format: :jpg)
      expect(page.response_headers['Content-Type']).to eq('image/jpg')
    end

    it "has a link to the allocation history",
       :raven_intercept_exception, vcr: { cassette_name: :link_to_allocation_history } do
      visit prison_prisoner_path('LEI', 'G7998GJ')
      click_link "View"
      expect(page).to have_content('Prisoner allocation')
    end

    it "has community information when present",
       :raven_intercept_exception, vcr: { cassette_name: :show_offender_community_info_full } do
      ldu = create(:local_divisional_unit, name: 'An LDU', email_address: 'test@example.com')
      team = create(:team, name: 'A team')
      create(:case_information,
             nomis_offender_id: alloc.nomis_offender_id,
             local_divisional_unit: ldu,
             team: team
      )

      alloc.update(com_name: 'Bob Smith')

      visit prison_prisoner_path('LEI', 'G7998GJ')

      expect(page).to have_content(ldu.name)
      expect(page).to have_content(ldu.email_address)
      expect(page).to have_content(team.name)
      expect(page).to have_content('Bob Smith')
    end

    it "has some community information when present",
       :raven_intercept_exception, vcr: { cassette_name: :show_offender_community_info_partial } do
      ldu = create(:local_divisional_unit, name: 'An LDU', email_address: nil)
      create(:case_information,
             nomis_offender_id: alloc.nomis_offender_id,
             local_divisional_unit: ldu
      )

      visit prison_prisoner_path('LEI', 'G7998GJ')

      expect(page).not_to have_content('Bob Smith')
      # Expect an Unknown for LDU Email and Team
      within '#community_information' do
        expect(page).to have_content('Unknown', count: 2)
      end
    end
  end
end
