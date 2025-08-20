require 'rails_helper'

feature 'POM onboarding' do
  let!(:prison) { Prison.find_by(code: 'LEI') || create(:prison, code: 'LEI') }
  let(:staff_id) { 123_456 }

  before do
    signin_spo_user
  end

  describe 'search staff page' do
    let(:search_query) { nil }
    let(:search_endpoint) { "#{ApiHelper::NOMIS_USER_ROLES_API_HOST}/users?caseload=#{prison.code}&nameFilter=#{search_query}&#{search_defaults}" }
    let(:search_defaults) { "size=100&status=ACTIVE&userType=GENERAL&accessRoles=ALLOC_CASE_MGR" }
    let(:search_response) { { totalElements: 0, content: [] } }

    before do
      stub_request(:get, search_endpoint)
        .to_return(status: 200, body: search_response.to_json)

      visit search_prison_onboarding_index_path(prison.code)
    end

    it 'is the search page' do
      expect(page).to have_title('Find a staff member – Digital Prison Services')
      expect(page).to have_css('label.govuk-label--l', text: 'Find a staff member')
      expect(page).to have_text('Use name, email address or username')
      expect(page).to have_css(
        '.govuk-hint', text: 'Search people who have not been added to the service yet'
      )
    end

    context 'when searching for staff' do
      let(:search_query) { '' }

      before do
        fill_in(id: 'pom-onboarding-form-search-query-field', with: search_query)
        click_button 'Search'
      end

      context 'when search term is too short (1 character)' do
        let(:search_query) { 'a' }

        it 'returns error message' do
          expect(page).to have_title('Find a staff member – Digital Prison Services')
          expect(page).to have_css('label.govuk-label--l', text: 'Find a staff member')
          expect(page).to have_css('p.govuk-error-message', text: 'Enter at least 3 characters')
        end
      end

      context 'when search term is too short (2 characters)' do
        let(:search_query) { 'ab' }

        it 'returns error message' do
          expect(page).to have_title('Find a staff member – Digital Prison Services')
          expect(page).to have_css('label.govuk-label--l', text: 'Find a staff member')
          expect(page).to have_css('p.govuk-error-message', text: 'Enter at least 3 characters')
        end
      end

      context 'when calling the search endpoint' do
        context 'when search term does not return results' do
          let(:search_query) { 'foobar' }

          it 'returns error message' do
            expect(page).to have_title('No results – Digital Prison Services')
            expect(page).to have_css('label.govuk-label--l', text: 'No results for foobar')
            expect(page).to have_text(
              'Search again or check with a local systems administrator that an account has been created for the person you are looking for.'
            )
          end
        end

        context 'when search term return results' do
          let(:search_query) { 'bloggs' }
          let(:search_response) do
            {
              totalElements: 1,
              content: [
                username: 'TEST_USER',
                staffId: staff_id,
                firstName: 'Joe',
                lastName: 'Bloggs',
                email: 'joe.bloggs@example.com',
              ]
            }
          end

          it 'shows the correct heading' do
            expect(page).to have_title('Search results – Digital Prison Services')
            expect(page).to have_css('label.govuk-label--l', text: 'Search results for bloggs')
          end

          it 'shows the results table' do
            expect(page).to have_link('Joe Bloggs', href: position_prison_onboarding_path(prison.code, staff_id))
            expect(page).to have_text('joe.bloggs@example.com')
            expect(page).to have_text('TEST_USER')
          end
        end
      end
    end

    context 'when staff has been already onboarded' do
      let(:search_query) { 'bloggs' }
      let(:search_response) do
        {
          totalElements: 2,
          content: [
            {
              username: 'TEST_USER',
              staffId: staff_id,
              firstName: 'Joe',
              lastName: 'Bloggs',
              email: 'joe.bloggs@example.com'
            },
            {
              username: 'ANOTHER_USER',
              staffId: 321_555,
              firstName: 'Jane',
              lastName: 'Bloggs',
              email: 'jane.bloggs@example.com'
            },
          ]
        }
      end

      before do
        allow_any_instance_of(Prison).to receive(:pom_details).and_return(
          [{ nomis_staff_id: staff_id }, { nomis_staff_id: 111_222 }]
        )

        fill_in(id: 'pom-onboarding-form-search-query-field', with: search_query)
        click_button 'Search'
      end

      it 'shows the results table excluding the onboarded POM' do
        expect(page).to have_text('Showing 1 to 1 of 1 results')
        expect(page).not_to have_text('Joe Bloggs')

        expect(page).to have_link('Jane Bloggs', href: position_prison_onboarding_path(prison.code, 321_555))
        expect(page).to have_text('jane.bloggs@example.com')
        expect(page).to have_text('ANOTHER_USER')
      end
    end
  end

  describe 'POM position page' do
    let(:pom_email) { 'joe.bloggs@example.com' }
    let(:pom) { build(:pom, :prison_officer, staffId: staff_id, primaryEmail: pom_email) }

    before do
      stub_pom(pom)
      stub_inexistent_filtered_pom(prison.code, staff_id)

      visit position_prison_onboarding_path(prison.code, staff_id)
    end

    it 'is the position page' do
      expect(page).to have_text(pom_email)
      expect(page).to have_css(
        'h1.govuk-heading-l', text: 'What type of POM is this person?'
      )
      expect(page).to have_css(
        'legend.govuk-fieldset__legend', text: 'Select one option'
      )
    end

    it 'gives an error if no radio option is selected' do
      click_button 'Continue'
      expect(page).to have_css('.govuk-error-summary', text: 'Select a type of POM')
    end

    it 'selects a position and continues to next step' do
      choose 'Prison POM'
      click_button 'Continue'
      expect(page).to have_text('What is this person\'s working pattern?')
    end
  end

  describe 'POM working pattern page' do
    let(:pom_email) { 'joe.bloggs@example.com' }
    let(:pom) { build(:pom, :prison_officer, staffId: staff_id, primaryEmail: pom_email) }

    before do
      stub_pom(pom)
      visit working_pattern_prison_onboarding_path(prison.code, staff_id)
    end

    it 'is the working pattern page' do
      expect(page).to have_text(pom_email)
      expect(page).to have_css(
        'legend.govuk-fieldset__legend', text: 'Select one option'
      )
    end

    it 'gives an error if no radio option is selected' do
      click_button 'Continue'
      expect(page).to have_css('.govuk-error-summary', text: 'Select full time or part time')
    end

    it 'gives an error if part time is selected but not days per week' do
      choose 'Part time'
      click_button 'Continue'
      expect(page).to have_css('.govuk-error-summary', text: 'Select how many days they will work')
    end

    context 'when next step' do
      before do
        # setup session form object to emulate completing previous steps
        allow_any_instance_of(OnboardingController).to receive(:read_from_session).and_return(
          { position: 'PO' }
        )
      end

      it 'selects a working pattern and continues to next step' do
        choose 'Part time'
        choose '2.5 days'
        click_button 'Continue'
        expect(page).to have_text('Check your answers')
      end
    end
  end

  describe 'Check your answers page' do
    let(:pom) { build(:pom, :probation_officer, staffId: staff_id, firstName: 'John', lastName: 'Doe') }
    let(:position) { pom.position }
    let(:schedule_type) { 'FT' }
    let(:working_pattern) { nil }

    before do
      # setup session form object to emulate completing previous steps
      allow_any_instance_of(OnboardingController).to receive(:read_from_session).and_return(
        { position:, schedule_type:, working_pattern: }
      )

      stub_pom(pom)
      visit check_answers_prison_onboarding_path(prison.code, staff_id)
    end

    it 'shows a summary of the answers with change links' do
      expect(page).to have_css('.govuk-summary-list__key', text: 'Name')
      expect(page).to have_css('.govuk-summary-list__value', text: 'John Doe')

      expect(page).to have_css('.govuk-summary-list__key', text: 'Type of POM')
      expect(page).to have_css('.govuk-summary-list__value', text: 'Probation POM')
      expect(page).to have_link('Change', href: position_prison_onboarding_path(prison.code, staff_id, from: :cya))

      expect(page).to have_css('.govuk-summary-list__key', text: 'Working pattern')
      expect(page).to have_css('.govuk-summary-list__value', text: 'Full time')
      expect(page).to have_link('Change', href: working_pattern_prison_onboarding_path(prison.code, staff_id))

      expect(page).to have_button('Cancel')
    end

    context 'when is part time working pattern' do
      let(:schedule_type) { 'PT' }
      let(:working_pattern) { 5 }

      it 'shows a summary of the answers' do
        expect(page).to have_css('.govuk-summary-list__key', text: 'Working pattern')
        expect(page).to have_css('.govuk-summary-list__value', text: 'Part time – 2.5 days per week')
        expect(page).to have_link('Change', href: working_pattern_prison_onboarding_path(prison.code, staff_id))
      end
    end

    context 'when changing the position answer' do
      it 'returns back to the check your answers page' do
        click_link 'Change', href: position_prison_onboarding_path(prison.code, staff_id, from: :cya)
        choose 'Prison POM'
        click_button 'Continue'
        expect(page).to have_text('Check your answers')
      end
    end

    context 'when confirm and submit' do
      before do
        allow(NomisUserRolesService).to receive(:add_pom).with(
          prison, staff_id, { position: 'PO', schedule_type: 'FT', hours_per_week: 37.5 }
        )

        # for the confirmation page
        stub_filtered_pom(prison.code, pom)
      end

      it 'creates the staff job classification and shows a confirmation page' do
        click_button 'Add POM'
        expect(page).to have_text('POM added')
        expect(page).to have_text('John Doe added as a probation POM')
        expect(page).to have_text('You can now allocate cases to probation POM John Doe.')
      end
    end
  end
end
