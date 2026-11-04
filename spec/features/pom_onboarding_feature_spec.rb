require 'rails_helper'

feature 'POM onboarding' do
  include_context 'with HMPPS audit event capture'

  let!(:prison) { Prison.find_by(code: 'LEI') || create(:prison, code: 'LEI') }
  let(:existing_poms) { [build(:pom, staffId: 111_222)] }
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
      stub_onboarded_poms(prison, existing_poms)

      stub_request(:get, search_endpoint)
        .to_return(status: 200, body: search_response.to_json)

      visit search_prison_onboarding_index_path(prison.code)
    end

    it 'is the search page' do
      expect(page).to have_title('Find a staff member – Digital Prison Services')
      expect(page).to have_css('label.govuk-label--l', text: 'Find a staff member')
      expect(page).to have_text('Use name, email address or username')
      expect(hmpps_audit_events).to be_empty
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
          expect(page.status_code).to eq(422)
          expect(hmpps_audit_events).to have_recorded_event('SEARCH_POM_ONBOARDING_STAFF', outcome: 'FAILURE', subject_id: 'a')
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
            expect(page).to have_text('Search again or ask a local systems administrator')
            expect(hmpps_audit_events.last[:details]).to include('results' => { 'resultCount' => 0, 'returnedSubjectIds' => [] })
          end
        end

        context 'when search term return results' do
          let(:search_query) { 'bloggs' }
          let(:search_response) do
            {
              totalElements: 1,
              content: [
                {
                  username: 'TEST_USER',
                  staffId: staff_id,
                  firstName: 'Joe',
                  lastName: 'Bloggs',
                  email: 'joe.bloggs@example.com'
                },
              ]
            }
          end

          it 'shows the correct heading' do
            expect(page).to have_title('Search results – Digital Prison Services')
            expect(page).to have_css('label.govuk-label--l', text: 'Search results for bloggs')
          end

          it 'shows the results table' do
            expect(page).to have_link('Joe Bloggs', href: position_prison_onboarding_path(prison.code, staff_id))
            expect(page).to have_css('td.govuk-table__cell[data-sort-value="Joe Bloggs"]')
            expect(page).to have_text('joe.bloggs@example.com')
            expect(page).to have_text('TEST_USER')

            stub_pom(build(:pom, staffId: staff_id))
            click_link 'Joe Bloggs'
            click_button 'Back'

            expect(page).to have_title('Search results – Digital Prison Services')
            expect(page).to have_link('Joe Bloggs')
          end

          it 'preserves navigation and session answers through cancellation and onboarding' do
            pom = build(:pom, :probation_officer, staffId: staff_id, firstName: 'Joe', lastName: 'Bloggs')
            stub_pom(pom)
            stub_inexistent_filtered_pom(prison.code, staff_id)
            allow(NomisUserRolesService).to receive(:add_pom).with(
              prison, staff_id, 'MOIC_POM', { position: 'PO', schedule_type: 'PT', hours_per_week: 18.75 }
            ) { stub_onboarded_poms(prison, [pom]) }

            click_link 'Joe Bloggs'
            choose 'Probation POM'
            click_button 'Continue'
            choose 'Part time'
            choose '2.5 days'
            click_button 'Continue'
            expect(page).to have_text('Check your answers')

            click_link 'Back'
            expect(page).to have_checked_field('Part time')
            expect(page).to have_checked_field('2.5 days')
            click_link 'Back'
            expect(page).to have_checked_field('Probation POM')
            click_button 'Continue'
            click_button 'Continue'
            click_button 'Cancel'
            expect(page).to have_field('search_query', with: 'bloggs')
            expect(page).to have_link('Joe Bloggs')
            expect(NomisUserRolesService).not_to have_received(:add_pom)

            click_link 'Joe Bloggs'
            expect(page).not_to have_checked_field('Probation POM')
            choose 'Probation POM'
            click_button 'Continue'
            expect(page).not_to have_checked_field('Part time')
            choose 'Part time'
            choose '2.5 days'
            click_button 'Continue'
            click_button 'Add POM'

            expect(page).to have_text('Joe Bloggs added as a probation POM')
            expect(NomisUserRolesService).to have_received(:add_pom).once
            click_link 'Add another POM'
            expect(find_field('search_query').value).to be_blank
          end
        end
      end
    end

    context 'when staff has been already onboarded' do
      let(:existing_poms) { [build(:pom, staffId: staff_id)] }
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
        fill_in(id: 'pom-onboarding-form-search-query-field', with: search_query)
        click_button 'Search'
      end

      it 'shows the results table excluding the onboarded POM' do
        expect(page).to have_text('Showing 1 to 1 of 1 results')
        expect(page).not_to have_text('Joe Bloggs')

        expect(page).to have_link('Jane Bloggs', href: position_prison_onboarding_path(prison.code, 321_555))
        expect(page).to have_text('jane.bloggs@example.com')
        expect(page).to have_text('ANOTHER_USER')
        expect(hmpps_audit_events).to have_recorded_event(
          'SEARCH_POM_ONBOARDING_STAFF', subject_type: 'SEARCH_TERM', subject_id: 'bloggs'
        )
        expect(hmpps_audit_events.last[:details]).to eq(
          'queryParams' => { 'prisonId' => prison.code },
          'results' => { 'resultCount' => 1, 'returnedSubjectIds' => ['321555'] }
        )
      end
    end

    it 'records a failed search when the staff service is unavailable' do
      allow(NomisUserRolesService).to receive(:search_staff).and_raise(IOError, 'Staff service unavailable')

      fill_in(id: 'pom-onboarding-form-search-query-field', with: 'bloggs')
      click_button 'Search'

      expect(page.status_code).to eq(500)
      expect(page).to have_title('There is a problem – Digital Prison Services')
      expect(hmpps_audit_events).to have_recorded_event('SEARCH_POM_ONBOARDING_STAFF', outcome: 'FAILURE', subject_id: 'bloggs')
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
      expect(hmpps_audit_events).to be_empty
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
          prison, staff_id, 'MOIC_POM', { position: 'PO', schedule_type: 'FT', hours_per_week: 37.5 }
        )

        # for the confirmation page
        stub_onboarded_poms(prison, [pom])
      end

      it 'creates the staff job classification and shows a confirmation page' do
        click_button 'Add POM'
        expect(page).to have_text('POM added')
        expect(page).to have_text('John Doe added as a probation POM')
        expect(page).to have_text('You can now allocate cases to probation POM John Doe.')
        expect(hmpps_audit_events).to have_recorded_event(
          'CREATE_POM_POSITION', subject_type: 'USER_ID', subject_id: staff_id.to_s
        )
        expect(hmpps_audit_events).to include(a_hash_including(
                                                what: 'CREATE_POM_POSITION_SUCCESS',
                                                details: { 'queryParams' => { 'prisonId' => prison.code }, 'position' => 'PO', 'workingPattern' => 1.0 }
                                              ))
      end

      it 'audits a failed onboarding without showing confirmation' do
        allow(NomisUserRolesService).to receive(:add_pom).and_raise(IOError, 'Staff service unavailable')

        click_button 'Add POM'

        expect(page.status_code).to eq(500)
        expect(page).to have_title('There is a problem – Digital Prison Services')
        expect(hmpps_audit_events).to have_recorded_event(
          'CREATE_POM_POSITION', outcome: 'FAILURE', subject_type: 'USER_ID', subject_id: staff_id.to_s
        )
      end
    end
  end
end
