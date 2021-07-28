require 'rails_helper'

feature 'email history' do
  let(:prison) { create(:prison) }
  let(:user) { build(:pom) }

  context 'when offender has less than 10 months left to serve' do
    let(:nomis_offender) {
      build(:nomis_offender,
            prisonId: prison.code,
            sentence: attributes_for(:sentence_detail, :less_than_10_months_to_serve))
    }
    let(:offender_no) { nomis_offender.fetch(:prisonerNumber) }

    before do
      stub_auth_token
      stub_offenders_for_prison(prison.code, [nomis_offender])
      stub_movements_for nomis_offender.fetch(:prisonerNumber), attributes_for_list(:movement, 1, toAgency: prison.code)

      stub_poms(prison.code, [user])
      stub_keyworker prison.code, offender_no, build(:keyworker)

      create(:case_information, offender: build(:offender, nomis_offender_id: offender_no))
      create(:allocation_history, nomis_offender_id: offender_no, primary_pom_nomis_id: user.staff_id, prison: prison.code)
      # we don't care about setting handover dates in Delius for this test
      allow(HmppsApi::CommunityApi).to receive(:set_handover_dates)

      # Ensure that an email history record has been created
      expect {
        RecalculateHandoverDateJob.perform_now(offender_no)
      }.to change(EmailHistory, :count).by(1)

      stub_signin_spo(user, [prison.code])
    end

    it 'does not display recalculate history records' do
      visit history_prison_prisoner_allocation_path prison.code, offender_no
      # expect only 1 prison record
      expect(all('.govuk-grid-row').size).to eq(1)
      # and expect only 1 timeline item (the allocation itself)
      within '.govuk-grid-row:nth-of-type(1)' do
        expect(all('.moj-timeline__item').size).to eq(1)
      end
    end
  end
end
