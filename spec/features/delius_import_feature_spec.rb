# frozen_string_literal: true

require 'rails_helper'

feature "Delius import feature", :disable_push_to_delius do
  let(:offender_no) {  offender.fetch(:prisonerNumber) }
  let(:prison_code) { create(:prison).code }
  let(:offender) { build(:nomis_offender, prisonId: prison_code) }
  let(:offender_name) { offender.fetch(:lastName) + ', ' + offender.fetch(:firstName) }
  let(:pom) { build(:pom) }

  before do
    stub_signin_spo(pom, [prison_code])
    stub_poms prison_code, [pom]
    stub_offenders_for_prison(prison_code, [offender])
  end

  context "when the LDU is known" do
    before do
      ldu = create(:local_delivery_unit)

      stub_community_offender(offender_no, build(:community_data,
                                                 offenderManagers: [
                                                     build(:community_offender_manager,
                                                           team: { code: 'XYX',
                                                                   localDeliveryUnit: { code: ldu.code } })]))
    end

    it "imports from Delius and creates case information" do
      visit missing_information_prison_prisoners_path(prison_code)
      expect(page).to have_content("Add missing details")
      expect(page).to have_content(offender_no)

      ProcessDeliusDataJob.perform_now offender_no

      reload_page
      expect(page).to have_content("Add missing details")
      expect(page).not_to have_content(offender_no)

      visit unallocated_prison_prisoners_path(prison_code)
      expect(page).to have_content("Make new allocations")
      expect(page).to have_content(offender_no)
      click_link offender_name
      expect(page.find(:css, '#welsh-offender-row')).not_to have_content('Change')
      expect(page.find(:css, '#service-provider-row')).not_to have_content('Change')
      expect(page.find(:css, '#tier-row')).not_to have_content('Change')
    end
  end
end
