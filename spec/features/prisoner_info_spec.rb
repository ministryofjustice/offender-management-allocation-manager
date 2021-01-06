require 'rails_helper'

feature 'View a prisoner profile page', :allocation do
  before do
    signin_spo_user
  end

  context 'without allocation' do
    it 'doesnt crash', vcr: { cassette_name: :show_unallocated_offender } do
      visit prison_prisoner_path('LEI', 'G7998GJ')

      expect(page).to have_css('h1', text: 'Ahmonis, Okadonah')
      expect(page).to have_content('07/07/1968')
      cat_code = find('h3#category-code').text
      expect(cat_code).to eq('C')
      expect(page).to have_css('#prisoner-case-type', text: 'Determinate')
    end
  end

  context 'with an allocation' do
    before do
      create(:case_information, nomis_offender_id: 'G7998GJ', victim_liaison_officers: [build(:victim_liaison_officer)])
      create(:allocation, nomis_offender_id: 'G7998GJ', primary_pom_nomis_id: '485637', primary_pom_name: 'Pobno, Kath')
    end

    let(:alloc) { Allocation.last }

    let(:initial_vlo) { VictimLiaisonOfficer.last }

    context 'without anything extra', vcr: { cassette_name: :show_offender_spec }  do
      before do
        visit prison_prisoner_path('LEI', 'G7998GJ')
      end

      scenario 'adding a VLO', :js do
        expect(page).to have_content('First Contact')
        click_link 'Add new VLO contact'
        find('.govuk-back-link')
        click_link 'Back'
        click_link 'Add new VLO contact'

        fill_in 'First name', with: 'Jim'
        # This fails as all fields not filled
        click_button 'Submit'

        # fill in missing fields and submit
        fill_in 'Last name', with: 'Smith'
        fill_in 'Email address', with: 'jim.smith@hotmail.com'
        click_button 'Submit'
        find '.vlo-row-1' # wait for page to load
        expect(page).to have_content('Smith, Jim')
        expect(page).to have_content('Second Contact')

        # As we had one already, ours is the second contact
        within '.vlo-row-1' do
          within '.change-email' do
            click_link 'Change'
          end
        end
        find('.govuk-back-link')
        click_link 'Back'
        within '.vlo-row-1' do
          within '.change-email' do
            click_link 'Change'
          end
        end

        # Blank out first name so it fails
        fill_in 'First name', with: ''
        click_button 'Submit'

        # Change first name
        fill_in 'First name', with: 'Mike'
        click_button 'Submit'
        expect(page).to have_content('Smith, Mike')

        # delete the contact we added earlier
        within '.vlo-row-1' do
          click_link 'Delete Contact'
        end
        click_button 'Confirm'
        # We should come back to the same page, but with our contact deleted
        expect(page).to have_content(initial_vlo.full_name)
        expect(page).not_to have_content('Smith, Mike')

        # Let's go and check out the allocation history
        click_link 'View'
        expect(page).to have_content('Victim Liaison Officer contact removed')
        expect(page).to have_content('by Pom, Moic')
      end

      it 'shows the prisoner information' do
        expect(page).to have_css('h1', text: 'Ahmonis, Okadonah')
        expect(page).to have_content('07/07/1968')
        cat_code = find('h3#category-code').text
        expect(cat_code).to eq('C')
      end

      it 'shows the POM name (fetched from NOMIS)' do
        # check the primary POM name stored in the allocation
        allocation = Allocation.last
        expect(allocation.primary_pom_name).to eq('Pobno, Kath')

        # ensure that the POM name displayed is the one actually returned from NOMIS
        pom_name = find('#primary_pom_name').text
        expect(pom_name).to eq('Pobee-Norris, Kath')
      end
    end

    context 'with an overridden reponsibility' do
      before do
        create(:responsibility, nomis_offender_id: 'G7998GJ')
      end

      it 'shows an overridden responsibility', vcr: { cassette_name: :show_offender_with_override_spec } do
        visit prison_prisoner_path('LEI', 'G7998GJ')

        expect(page).to have_content('Supporting')
      end
    end

    it 'shows the prisoner image', vcr: { cassette_name: :show_offender_spec_image } do
      visit prison_prisoner_image_path('LEI', 'G7998GJ', format: :jpg)
      expect(page.response_headers['Content-Type']).to eq('image/jpg')
    end

    it "has a link to the allocation history", vcr: { cassette_name: :link_to_allocation_history } do
      visit prison_prisoner_path('LEI', 'G7998GJ')
      click_link "View"
      expect(page).to have_content('Prisoner allocated')
    end

    it 'displays the non-disclosable badge on the VLO table', vcr: { cassette_name: :vlo_non_disclosable_badge } do
      visit prison_prisoner_path('LEI', 'G7998GJ')
      expect(page).to have_css('#non-disclosable-badge', text: 'Non-Disclosable')
    end
  end

  context 'with community information' do
    it "has community information when present",
       vcr: { cassette_name: :show_offender_community_info_full } do
      ldu = create(:local_divisional_unit, name: 'An LDU', email_address: 'test@example.com')
      team = create(:team, name: 'A team', local_divisional_unit: ldu)
      create(:case_information,
             nomis_offender_id: 'G7998GJ',
             team: team,
             com_name: 'Bob Smith'
      )

      visit prison_prisoner_path('LEI', 'G7998GJ')

      expect(page).to have_content(ldu.name)
      expect(page).to have_content(ldu.email_address)
      expect(page).to have_content(team.name)
      expect(page).to have_content('Bob Smith')
    end

    it "has some community information when present",
       vcr: { cassette_name: :show_offender_community_info_partial } do
      ldu = create(:local_divisional_unit, name: 'An LDU', email_address: nil)
      team = create(:team, local_divisional_unit: ldu)
      create(:case_information,
             nomis_offender_id: 'G7998GJ',
             team: team
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
