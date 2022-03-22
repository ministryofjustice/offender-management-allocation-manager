require 'rails_helper'

RSpec.feature "ChangeParoleReviewDates", type: :feature do
  let(:prison) { create(:prison) }
  let(:tariff_date) { Time.zone.today + 1.year }
  let(:existing_prd) { nil }
  let(:nomis_offender_id) { nomis_offender.fetch(:prisonerNumber) }

  # Stub API response to represent an offender in NOMIS
  let(:nomis_offender) do
    build(:nomis_offender, prisonId: prison.code,
                           sentence: attributes_for(:sentence_detail, :indeterminate, tariffDate: tariff_date)
    )
  end

  # Create an Offender record and associated CaseInformation record
  let!(:offender_record) do
    create(:offender, nomis_offender_id: nomis_offender_id, case_information: build(:case_information))
  end

  let(:user) do
    # 'pom' is a misleading name for this factory. It actually represents any NOMIS user/staff member.
    build(:pom)
  end

  before do
    stub_offenders_for_prison(prison.code, [nomis_offender])
    stub_keyworker(prison.code, nomis_offender_id, build(:keyworker))

    if existing_prd.present?
      offender_record.create_parole_record!(parole_review_date: existing_prd)
    end
  end

  shared_examples 'update PRD behaviour' do
    context 'when the TED is in the future and no PRD has been entered' do
      let(:tariff_date) { Time.zone.today + 1.year }

      it 'does not allow PRD to be entered' do
        expect(value_for_row('Tariff date')).to eq(tariff_date.to_s(:rfc822))
        expect(value_for_row('Parole Review date')).to eq('Unknown')
        expect(td_for_row('Parole Review date')).to have_no_link
      end
    end

    context 'when PRD is blank' do
      let(:tariff_date) { Faker::Date.backward }
      let(:existing_prd) { nil }
      let(:new_prd) { Faker::Date.forward }

      # Form input values (zero-padded, e.g. "05")
      let(:valid_day) { sprintf('%02d', new_prd.day) }
      let(:valid_month) { sprintf('%02d', new_prd.month) }
      let(:valid_year) { new_prd.year }
      let(:invalid_year) { 2.years.ago.year }

      it 'can be set' do
        expect(value_for_row('Parole Review date')).to start_with('Unknown')
        td_for_row('Parole Review date').click_link('Update')

        # Enter a date in the past and expect a validation error
        fill_in 'Day', with: valid_day
        fill_in 'Month', with: valid_month
        fill_in 'Year', with: invalid_year
        click_button 'Update'
        expect(page).to have_content('There is a problem')

        # Change it to a future date
        # Valid day and month should have been remembered, so no need to re-enter them
        fill_in 'Year', with: valid_year
        click_button 'Update'

        # Expect to see the new date on the profile page
        expect(value_for_row('Parole Review date')).to start_with(new_prd.to_s(:rfc822))
        expect(td_for_row('Parole Review date')).to have_link('Update')
      end
    end

    context 'when PRD has already been entered' do
      let(:tariff_date) { Faker::Date.backward }
      let(:existing_prd) { Faker::Date.backward }
      let(:new_prd) { Faker::Date.forward }

      # Form input values (zero-padded, e.g. "05")
      let(:valid_day) { sprintf('%02d', new_prd.day) }
      let(:valid_month) { sprintf('%02d', new_prd.month) }
      let(:valid_year) { new_prd.year }
      let(:invalid_year) { 2.years.ago.year }

      it 'can be updated' do
        expect(value_for_row('Parole Review date')).to start_with(existing_prd.to_s(:rfc822))
        td_for_row('Parole Review date').click_link('Update')

        # Enter a date in the past and expect a validation error
        fill_in 'Day', with: valid_day
        fill_in 'Month', with: valid_month
        fill_in 'Year', with: invalid_year
        click_button 'Update'
        expect(page).to have_content('There is a problem')

        # Change it to a future date
        # Valid day and month should have been remembered, so no need to re-enter them
        fill_in 'Year', with: valid_year
        click_button 'Update'

        # Expect to see the new date on the profile page
        expect(value_for_row('Parole Review date')).to start_with(new_prd.to_s(:rfc822))
        expect(td_for_row('Parole Review date')).to have_link('Update')
      end
    end
  end

  context 'when user is a HOMD' do
    before do
      # Stub the user to be a HOMD
      stub_signin_spo(user, [prison.code])
      stub_poms(prison.code, [])

      # Navigate to the "Allocate a POM" page
      visit prison_dashboard_index_path(prison.code)
      click_link 'Make new allocations'
      page.find('[aria-label="Prisoner name"] a').click
    end

    include_examples 'update PRD behaviour'
  end

  context 'when user is a POM' do
    before do
      # Stub the user to be a POM
      stub_auth_token
      signin_pom_user [prison.code]
      stub_spo_user(user) # this stub method has a misleading name - it stubs any NOMIS user/staff member
      stub_poms(prison.code, [user])

      # Add the offender to the POM's case list
      create(
        :allocation_history,
        nomis_offender_id: nomis_offender_id,
        primary_pom_nomis_id: user.staff_id,
        prison: prison.code
      )

      # Navigate to the prisoner profile page
      visit prison_dashboard_index_path(prison.code)
      click_link 'See your caseload'
      click_link 'Your cases (1)'
      page.find('#all-cases [aria-label="Prisoner name"] a').click
    end

    include_examples 'update PRD behaviour'
  end
end
