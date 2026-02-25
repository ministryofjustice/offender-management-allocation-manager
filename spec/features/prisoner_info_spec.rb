describe 'View a prisoner profile page' do
  let(:prison) { create(:prison, code: 'LEI') }

  let(:offender) { build(:stubbed_offender, nomis_id: 'G1234AB', first_name: 'Any', last_name: 'Case', dob: '1999-12-01') }

  before do
    stub_signin_spo(build(:homd))
    stub_offenders_for_prison(prison.code, [offender])
  end

  context 'with unallocated cases missing case information' do
    before { CaseInformation.find_by(nomis_offender_id: 'G1234AB').destroy }

    it 'shows basic details about the case' do
      visit prison_prisoner_path(prison.code, 'G1234AB')

      expect(page).to have_content('Case, Any')
      within('div', text: 'Date of birth', match: :first) { expect(page).to have_content('01 Dec 1999') }
      within('div', text: 'Category', match: :first) { expect(page).to have_content('Cat C') }
    end
  end

  context 'with an existing early allocation' do
    before { create(:early_allocation, nomis_offender_id: 'G1234AB', created_within_referral_window: within_window) }

    context 'with an old early allocation' do
      let(:within_window) { false }

      it 'shows a notification' do
        visit prison_prisoner_path(prison.code, 'G1234AB')
        expect(page).to have_text('Case, Any might be eligible for early allocation to the community probation team')
      end
    end

    context 'with an new early allocation' do
      let(:within_window) { true }

      it 'does not show a notification' do
        visit prison_prisoner_path(prison.code, 'G1234AB')
        expect(page).not_to have_text('eligible for early allocation to the community probation team')
      end
    end
  end

  context 'when case is allocated' do
    let(:pom) { build(:pom, staffId: 1234, firstName: 'A', lastName: 'Pom') }

    before do
      stub_poms(prison.code, [pom])
      create(:allocation_history, nomis_offender_id: 'G1234AB', primary_pom_nomis_id: 1234, primary_pom_name: 'A Pom', prison: prison.code)
      local_delivery_unit = create(:local_delivery_unit, name: 'An LDU', email_address: 'test@example.com')
      CaseInformation.find_by(nomis_offender_id: 'G1234AB').update(local_delivery_unit:, team_name: 'Team X', com_name: 'Bob Smith')
      create(:victim_liaison_officer, nomis_offender_id: 'G1234AB', first_name: 'Vii', last_name: 'Ello')
    end

    it 'shows basic details about the case' do
      visit prison_prisoner_path(prison.code, 'G1234AB')

      expect(page).to have_content('Case, Any')
      within('div', text: 'Date of birth', match: :first) { expect(page).to have_content('01 Dec 1999') }
      within('div', text: 'Category', match: :first) { expect(page).to have_content('Cat C') }
      within('table', text: 'Prison allocation') { expect(page).to have_content('A Pom') }
      expect(page).to have_content('POM role Responsible')
      expect(page).to have_content('Local divisional unit (LDU) An LDU')
      expect(page).to have_content('Local divisional unit (LDU) email address test@example.com')
      expect(page).to have_content('Team Team X')
      expect(page).to have_content('Community Offender Manager (COM) name Bob Smith')
      within('table', text: 'Victim liaison officer (VLO)') do
        expect(page).to have_content('Non-Disclosable')
        expect(page).to have_content('Victim liaison officer name Vii Ello')
      end

      # Demonstrate POM roles changing when overridden
      create(:responsibility, :com, nomis_offender_id: 'G1234AB')
      visit prison_prisoner_path(prison.code, 'G1234AB')

      expect(page).to have_content('POM role Supporting')
    end

    it 'can add and remove VLOs to the case' do
      visit prison_prisoner_path(prison.code, 'G1234AB')

      click_link 'Add new VLO contact'
      fill_in 'First name', with: 'Jim'
      # This fails as all fields not filled
      click_button 'Save details'
      # fill in missing fields and submit
      fill_in 'Last name', with: 'Smith'
      # email has leading and trailing whitespaces, that are removed before validation
      fill_in 'Email address', with: ' jim.smith@hotmail.com '
      click_button 'Save details'

      within('table', text: 'Victim liaison officer (VLO)') do
        expect(page).to have_content('Victim liaison officer name Vii Ello')
        expect(page).to have_content('Victim liaison officer name Jim Smith')
      end

      # As we had one already, ours is the second contact
      within '.vlo-row-1 tr', text: 'Email address jim.smith@hotmail.com' do
        click_link 'Change'
      end

      # Blank out first name so it fails
      fill_in 'First name', with: ''
      click_button 'Save details'
      # Change first name
      fill_in 'First name', with: 'Mike'
      click_button 'Save details'

      within('table', text: 'Victim liaison officer (VLO)') do
        expect(page).to have_content('Victim liaison officer name Vii Ello')
        expect(page).to have_content('Victim liaison officer name Mike Smith')
      end

      # delete the contact we added earlier
      within '.vlo-row-1 tr', text: 'Second Contact' do
        click_link 'Delete Contact'
      end
      choose 'Yes'
      click_button 'Confirm'

      within('table', text: 'Victim liaison officer (VLO)') do
        expect(page).to have_content('Victim liaison officer name Vii Ello')
        expect(page).not_to have_content('Victim liaison officer name Mike Smith')
      end

      stub_movements_for('G1234AB', [attributes_for(:movement)])

      # Let's go and check out the allocation history
      within('tr', text: 'Allocation history') { click_link 'View' }
      within('.moj-timeline__item', text: 'Contact removed') { expect(page).to have_content('by Pom, Moic') }
    end
  end

  context 'when case is outside omic policy' do
    let(:offender) { build(:stubbed_offender, nomis_id: 'G1234AB', first_name: 'Any', last_name: 'Case', sentence_type: :outside_omic_policy) }

    it 'informs the user' do
      visit prison_prisoner_path(prison.code, 'G1234AB')
      expect(page).to have_content("Outside OMIC policy\nAny Case cannot be displayed because they don't fall under OMIC policy")
    end
  end

  context 'when the case needs a COM allocating' do
    let(:offender) { build(:stubbed_offender, nomis_id: 'G1234AB', responsibility: :com, first_name: 'Any', last_name: 'Case') }

    before { CaseInformation.find_by(nomis_offender_id: 'G1234AB').update(com_name: nil) }

    it 'informs the user' do
      visit prison_prisoner_path(prison.code, 'G1234AB')
      expect(page).to have_content('COM allocation overdue')
      expect(page).to have_css('#com-name.app-table__cell--error')
    end
  end
end
