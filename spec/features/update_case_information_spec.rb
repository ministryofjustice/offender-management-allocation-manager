require 'rails_helper'

RSpec.feature "Update case information", type: :feature do
  let(:offender) { build(:nomis_offender, complexityLevel: 'high', agencyId: prison.code) }
  let(:offenders) { [offender] }
  let(:pom) { build(:pom) }
  let(:spo) { build(:pom) }
  let(:prison) { create(:prison) }
  let(:offender_no) { offender.fetch(:offenderNo) }

  before do
    stub_offenders_for_prison(prison.code, offenders)
    stub_signin_spo(spo, [prison.code])
    stub_poms(prison.code, [pom, spo])
    stub_keyworker(prison.code, offender.fetch(:offenderNo), build(:keyworker))
  end

  context 'when there is a new allocation' do
    before do
      create(:case_information, offender: build(:offender, nomis_offender_id: offender_no))
    end

    it 'returns to the Allocate a POM page' do
      visit prison_prisoner_staff_index_path(prison_id: prison.code, prisoner_id: offender_no)

      # This takes you to the change case information edit page
      within(:css, "td#tier") do
        click_link('Change')
      end

      # This returns you back from where you came (Allocation information page)
      click_on('Update')

      expect(page).to have_current_path(prison_prisoner_staff_index_path(prison_id: prison.code, prisoner_id: offender_no))
    end
  end

  context 'when there is an existing allocation' do
    before do
      create(:allocation_history, nomis_offender_id: offender_no, primary_pom_nomis_id: pom.staff_id,  prison: prison.code)
      create(:case_information, offender: build(:offender, nomis_offender_id: offender_no))
    end

    it 'returns to the prisoner Allocation information page' do
      visit prison_prisoner_allocation_path(prison_id: prison.code, prisoner_id: offender_no)

      # This takes you to the change case information edit page
      within(:css, "td#tier") do
        click_link('Change')
      end

      # This returns you back from where you came (Allocation information page)
      click_on('Update')

      expect(page).to have_current_path(prison_prisoner_allocation_path(prison_id: prison.code, prisoner_id: offender_no))
    end
  end

  context 'when reallocating a POM on an existing allocation' do
    before do
      create(:allocation_history, nomis_offender_id: offender_no, primary_pom_nomis_id: pom.staff_id,  prison: prison.code)
      create(:case_information, offender: build(:offender, nomis_offender_id: offender_no))
    end

    it 'returns to the Reallocate POM page' do
      visit prison_prisoner_allocation_path(prison_id: prison.code, prisoner_id: offender_no)

      # To reallocate the pom page
      click_link('Reallocate')

      # To take you to the change case information edit page
      within(:css, "td#tier") do
        click_link('Change')
      end

      # This returns you back from where you came (Reallocate Pom page)
      click_on('Update')

      expect(page).to have_current_path(prison_prisoner_staff_index_path(prison_id: prison.code, prisoner_id: offender_no))
    end
  end
end