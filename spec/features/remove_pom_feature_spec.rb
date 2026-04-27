# frozen_string_literal: true

require 'rails_helper'

feature "remove a POM no longer present in NOMIS" do
  let(:limbo_bulk_reallocation_enabled) { true }
  let!(:prison) { Prison.find_by(code: "LEI") || create(:prison, code: "LEI") }
  let(:spo) { build(:pom) }
  let(:probation_poms) do
    [
      build(:pom, :probation_officer),
      build(:pom, :probation_officer)
    ]
  end

  before do
    stub_feature_flag(:limbo_bulk_reallocation, enabled: limbo_bulk_reallocation_enabled)

    stub_pom(spo)
    stub_signin_spo(spo, [prison.code])
    stub_poms(prison.code, probation_poms)
  end

  shared_context 'with a removed pom with cases in limbo' do
    let(:removed_pom_staff_id) { 123_456 }
    let(:removed_pom) { build(:pom, staffId: removed_pom_staff_id, firstName: 'JOHN', lastName: 'DOE') }
    let(:offenders_in_prison) { build_list(:nomis_offender, 1, prisonId: prison.code) }

    before do
      # Create a POM that is present locally but not remotely
      PomDetail.find_or_create_by!(
        prison_code: prison.code, nomis_staff_id: removed_pom_staff_id, status: 'active', working_pattern: 1.0
      )

      stub_pom(removed_pom)
      stub_inexistent_filtered_pom(prison.code, removed_pom_staff_id)
      stub_offenders_for_prison(prison.code, offenders_in_prison)

      offenders_in_prison.each do |offender|
        nomis_offender_id = offender[:prisonerNumber]
        offender = create(:offender, nomis_offender_id:)

        Timecop.travel Date.new(2025, 6, 22) do
          create(:allocation_history, :primary, prison: prison.code, nomis_offender_id:, primary_pom_nomis_id: removed_pom_staff_id)
          create(:case_information, offender:)
        end
      end

      # Goes to the Manage your staff page
      visit prison_poms_path(prison_id: prison.code)
    end
  end

  shared_examples 'without an attention needed tab' do
    it 'does not show the attention needed tab' do
      visit prison_poms_path(prison_id: prison.code)

      expect(page).not_to have_css('a.govuk-tabs__tab', text: 'Attention needed')
    end
  end

  shared_examples 'with an attention needed tab' do
    it 'shows the attention needed tab' do
      expect(page).to have_css('a.govuk-tabs__tab', text: 'Attention needed')
      expect(page).to have_css('#attention-needed-badge', text: '1')
    end
  end

  context 'when limbo bulk reallocation is enabled' do
    let(:limbo_bulk_reallocation_enabled) { true }

    context 'when there are no POMs with cases in limbo' do
      include_examples 'without an attention needed tab'
    end

    context 'when there are POMs with primary cases in limbo' do
      include_context 'with a removed pom with cases in limbo'
      include_examples 'with an attention needed tab'

      it 'shows the updated attention needed copy and reallocation action' do
        click_link 'Attention needed'

        within('section#attention_needed') do
          expect(page).to have_text("These staff members' cases need reallocating so they can be removed from this service.")
          expect(page).to have_css('td.govuk-table__cell[aria-label="POM"]', text: 'John Doe')
          expect(page).to have_css('td.govuk-table__cell[aria-label="Last case allocated"]', text: '22 June 2025')
          expect(page).to have_css('td.govuk-table__cell[aria-label="Total cases"]', text: '1')
          expect(page).to have_link('Reallocate cases', href: confirm_removal_prison_pom_path(prison.code, removed_pom_staff_id, from: :attention_needed))
          expect(page).not_to have_button('Remove POM')
        end
      end

      it 'takes the user to the confirmation page' do
        within('section#attention_needed') do
          click_link 'Reallocate cases'
        end

        expect(page).to have_css('h1.govuk-heading-l', text: 'Confirm John Doe can be removed from this service')
        expect(page).to have_link('Continue', href: reallocate_prison_pom_path(prison.code, removed_pom_staff_id))
      end
    end
  end

  context 'when limbo bulk reallocation is disabled' do
    let(:limbo_bulk_reallocation_enabled) { false }

    context 'when there are no POMs with cases in limbo' do
      include_examples 'without an attention needed tab'
    end

    context 'when there are POMs with primary cases in limbo' do
      include_context 'with a removed pom with cases in limbo'
      include_examples 'with an attention needed tab'

      it 'shows the legacy attention needed copy and remove action' do
        click_link 'Attention needed'

        within('section#attention_needed') do
          expect(page).to have_text('These people are no longer recorded as POMs on NOMIS or Digital Prison Services. You must remove them from this service and then reallocate their cases.')
          expect(page).to have_css('td.govuk-table__cell[aria-label="POM"]', text: 'John Doe')
          expect(page).to have_css('td.govuk-table__cell[aria-label="Last case allocated"]', text: '22 June 2025')
          expect(page).to have_css('td.govuk-table__cell[aria-label="Total cases"]', text: '1')
          expect(page).to have_css('td.govuk-table__cell[aria-label="Action"]', text: 'Remove POM')
          expect(page).not_to have_link('Reallocate cases')
        end
      end

      it 'removes the POM' do
        within('section#attention_needed') do
          click_button 'Remove POM'
        end

        expect(page).to have_css('.moj-banner--success',
                                 text: 'John Doe removed. If necessary, their cases have been moved to the allocations list.')

        expect(page).to have_link('the allocations list',
                                  href: unallocated_prison_prisoners_path(prison))

        pom_details = PomDetail.find_by(prison_code: prison.code, nomis_staff_id: removed_pom_staff_id)
        expect(pom_details).to be_nil
      end
    end
  end
end
