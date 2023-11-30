RSpec.feature "Delius import feature", :disable_push_to_delius do
  let(:offender_no) {  offender.fetch(:prisonerNumber) }
  let(:prison) { create(:prison) }
  let(:prison_code) { prison.code }
  let(:offender) { build(:nomis_offender, prisonId: prison_code) }
  let(:offender_name) { "#{offender.fetch(:lastName)}, #{offender.fetch(:firstName)}" }
  let(:pom) { build(:pom) }

  before do
    stub_signin_spo(pom, [prison_code])
    stub_poms prison_code, [pom]
    stub_offenders_for_prison(prison_code, [offender])
    stub_request(:get, "https://www.gov.uk/bank-holidays.json").to_return(body: {}.to_json)

    create(:allocation_history, nomis_offender_id: offender_no, prison: prison.code, primary_pom_nomis_id: pom.staff_id)
    allow(RecalculateHandoverDateJob).to receive_messages(perform_now: nil, perform_later: nil)
  end

  context "when the LDU is known" do
    before do
      ldu = create(:local_delivery_unit)

      stub_community_offender(offender_no, build(:community_data,
                                                 offenderManagers: [
                                                   build(:community_offender_manager,
                                                         staff: { forenames: 'F1', surname: 'S1' },
                                                         team: { description: 'Team1',
                                                                 localDeliveryUnit: { code: ldu.code } })]))

      stub_get_all_offender_managers(offender_no, [build(:community_all_offender_managers_datum,
                                                         forenames: com_forename, surname: com_surname, email: com_email,
                                                         team_name: 'Team1', ldu_code: ldu.code)])
      stub_keyworker(prison_code, offender_no, build(:keyworker))

      allow(OffenderService).to receive(:get_probation_record).with(offender_no)
        .and_return(mock_probation_record)
    end

    let(:com_forename) { 'F1' }
    let(:com_surname) { 'S1' }
    let(:com_email) { 'E1' }

    let(:mock_probation_record) do
      build :probation_record, offender_no: offender_no,
                               com_forename: com_forename,
                               com_surname: com_surname,
                               com_email: com_email
    end

    it "imports from Delius and creates case information" do
      visit missing_information_prison_prisoners_path(prison_code)
      expect(page).to have_content("Add missing details")
      expect(page).to have_content(offender_no)

      ProcessDeliusDataJob.perform_now offender_no

      expect(DeliusImportError.all).to eq []

      reload_page
      expect(page).to have_content("Add missing details")
      expect(page).not_to have_content(offender_no)

      visit allocated_prison_prisoners_path(prison_code)
      expect(page).to have_content("See allocations")
      expect(page).to have_content(offender_no)
      click_link offender_name

      expect(page.find(:css, '#welsh-offender-row')).not_to have_content('Change')
      expect(page.find(:css, '#service-provider-row')).not_to have_content('Change')
      expect(page.find(:css, '#tier-row')).not_to have_content('Change')

      expect(Offender.find(offender_no).case_information.values_at(:com_name, :com_email)).to eq ["#{com_surname}, #{com_forename}", com_email]
    end
  end
end
