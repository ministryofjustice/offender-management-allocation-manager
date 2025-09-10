# frozen_string_literal: true

require 'rails_helper'

feature "remove a POM no longer present in NOMIS" do
  let!(:prison) { Prison.find_by(code: "LEI") || create(:prison, code: "LEI") }
  let(:spo) { build(:pom) }
  let(:probation_poms) do
    [
      build(:pom, :probation_officer),
      build(:pom, :probation_officer)
    ]
  end

  before do
    stub_pom(spo)
    stub_signin_spo(spo, [prison.code])
    stub_poms(prison.code, probation_poms)
  end

  context 'when there are no POMs with cases in limbo' do
    before do
      # Goes to the Manage your staff page
      visit prison_poms_path(prison_id: prison.code)
    end

    it 'does not show the attention needed tab' do
      expect(page).not_to have_css('a.govuk-tabs__tab', text: 'Attention needed')
    end
  end

  context 'when there are POMs with cases in limbo' do
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

    it 'shows the attention needed tab' do
      expect(page).to have_css('a.govuk-tabs__tab', text: 'Attention needed')
      expect(page).to have_css('#attention-needed-badge', text: '1')
    end

    it 'shows the removed POMs with details' do
      click_link 'Attention needed'
      expect(page).to have_css('h2.govuk-heading-l', text: 'Attention needed')

      within('section#attention_needed') do
        expect(page).to have_css('td.govuk-table__cell[aria-label="POM"]', text: 'John Doe')
        expect(page).to have_css('td.govuk-table__cell[aria-label="Last case allocated"]', text: '22 June 2025')
        expect(page).to have_css('td.govuk-table__cell[aria-label="Total cases"]', text: '1')
        expect(page).to have_css('td.govuk-table__cell[aria-label="Action"]', text: 'Remove POM')
      end
    end

    it 'removes the POM' do
      within('section#attention_needed') do
        click_button 'Remove POM'
      end

      expect(page).to have_css('.moj-banner--success',
                               text: 'John Doe removed. Their cases have been moved to the allocations list.')

      expect(page).to have_link('the allocations list',
                                href: unallocated_prison_prisoners_path(prison))

      pom_details = PomDetail.find_by(prison_code: prison.code, nomis_staff_id: removed_pom_staff_id)
      expect(pom_details).to be_nil
    end
  end
end
