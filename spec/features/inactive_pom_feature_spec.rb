require 'rails_helper'

feature 'Inactive POM' do
  context 'when viewing an inactive POMs caseload' do
    let(:prison) { Prison.find_by(code: "LEI") || create(:prison, code: "LEI") }
    let(:prison_code) { prison.code }

    let(:active_pom) { build(:pom, staffId: 485_926) }
    let(:inactive_pom) { build(:pom, staffId: 485_595) }
    let(:nomis_offender_id) { "G7266VD" }
    let(:nomis_offender) { [build(:nomis_offender, prisonId: prison_code, prisonerNumber: nomis_offender_id)] }

    before do
      stub_poms(prison_code, [active_pom])
      stub_signin_spo(active_pom, prison_code)
      stub_offenders_for_prison(prison.code, nomis_offender)
      stub_keyworker(prison_code, nomis_offender_id, staffId: 123_456)

      create(
        :allocation_history,
        prison: prison_code,
        nomis_offender_id: nomis_offender_id,
        primary_pom_nomis_id: inactive_pom.staffId,
        secondary_pom_nomis_id: active_pom.staffId
      )

      create(:case_information, offender: build(:offender, nomis_offender_id:))
      create(:pom_detail, :inactive, prison_code: prison_code, nomis_staff_id: inactive_pom.staffId)

      visit prison_prisoner_allocation_path(prison_code, nomis_offender_id)
    end

    it "displays instruction links" do
      expect(page).to have_text('Check this POM is still active')
      expect(page).to have_link('following these instructions', href: help_step2_path)
      expect(page).to have_link('use these instructions', href: help_step3_path)
    end
  end
end
