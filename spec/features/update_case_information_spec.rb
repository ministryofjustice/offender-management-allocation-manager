require 'rails_helper'

RSpec.feature "Update case information", type: :feature do
  let(:offender) { build(:nomis_offender, complexityLevel: 'high', prisonId: prison.code) }
  let(:offenders) { [offender] }
  let(:pom) { build(:pom) }
  let(:spo) { build(:pom) }
  let(:prison) { create(:prison) }
  let(:offender_no) { offender.fetch(:prisonerNumber) }

  before do
    stub_offenders_for_prison(prison.code, offenders)
    stub_signin_spo(spo, [prison.code])
    stub_poms(prison.code, [pom, spo])
    stub_keyworker(offender_no)
    stub_community_offender(offender_no, build(:community_data))
    allow_any_instance_of(MpcOffender).to receive(:rosh_summary).and_return(RoshSummary.missing)
  end

  context 'when there is a new allocation' do
    before do
      create(:case_information, offender: build(:offender, nomis_offender_id: offender_no))
    end

    it 'returns to review case details after updating from review case details' do
      visit prison_prisoner_review_case_details_path(prison_id: prison.code, prisoner_id: offender_no)

      within('tr#tier') do
        click_link('Change')
      end

      click_on('Update')

      expect(page).to have_current_path(prison_prisoner_review_case_details_path(prison_id: prison.code, prisoner_id: offender_no))
    end
  end

  context 'when there is an existing allocation' do
    before do
      create(:allocation_history, nomis_offender_id: offender_no, primary_pom_nomis_id: pom.staff_id,  prison: prison.code)
      create(:case_information, offender: build(:offender, nomis_offender_id: offender_no))
    end

    it 'returns to allocation information after updating from allocation information' do
      visit prison_prisoner_allocation_path(prison_id: prison.code, prisoner_id: offender_no)

      within('td#tier') do
        click_link('Change')
      end

      click_on('Update')

      expect(page).to have_current_path(prison_prisoner_allocation_path(prison_id: prison.code, prisoner_id: offender_no))
    end
  end

  context 'when the update is invalid' do
    before do
      create(:allocation_history, nomis_offender_id: offender_no, primary_pom_nomis_id: pom.staff_id,  prison: prison.code)
      create(:case_information,
             offender: build(:offender, nomis_offender_id: offender_no),
             tier: 'B',
             enhanced_resourcing: nil)
    end

    it 'keeps the allocation-information back link after a validation error' do
      visit prison_prisoner_allocation_path(prison_id: prison.code, prisoner_id: offender_no)

      within('td#tier') do
        click_link('Change')
      end

      click_on('Update')

      expect(page).to have_content('There is a problem')

      click_link('Back')

      expect(page).to have_current_path(prison_prisoner_allocation_path(prison_id: prison.code, prisoner_id: offender_no))
    end
  end
end
