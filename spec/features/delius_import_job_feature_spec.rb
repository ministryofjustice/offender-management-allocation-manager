# frozen_string_literal: true

require 'rails_helper'
require 'support/lib/mock_imap'
require 'support/lib/mock_mail'
require 'delius_import_job'

RSpec.shared_examples "imports the Delius spreadsheet and creates case information" do
  it "imports the Delius spreadsheet and creates case information" do
    visit prison_summary_pending_path(prison)
    expect(page).to have_content("Add missing information")
    expect(page).to have_content(offender_no)

    ProcessDeliusDataJob.perform_now offender_no

    reload_page
    expect(page).to have_content("Add missing information")
    expect(page).not_to have_content(offender_no)

    visit prison_summary_unallocated_path(prison)
    expect(page).to have_content("Make allocations")
    expect(page).to have_content(offender_no)
    click_link 'Allocate'
    expect(page.find(:css, '#welsh-offender-row')).not_to have_content('Change')
    expect(page.find(:css, '#service-provider-row')).not_to have_content('Change')
    expect(page.find(:css, '#tier-row')).not_to have_content('Change')
  end
end

feature "Delius import feature", :disable_push_to_delius do
  let(:stub_auth_host) { Rails.configuration.nomis_oauth_host }
  let(:stub_api_host) { "#{Rails.configuration.prison_api_host}/api" }
  let(:offender_no) {  'G4281GV' }
  let(:prison) { build(:prison).code }
  let(:offender) { build(:nomis_offender, offenderNo: offender_no) }
  let(:pom) { build(:pom) }

  before do
    stub_signin_spo(pom, [prison])
    stub_poms prison, [pom]
    stub_offender(offender)
    stub_offenders_for_prison(prison, [offender])

    stub_request(:post, "#{stub_api_host}/movements/offenders?latestOnly=false&movementTypes=TRN").
      with(body: [offender_no].to_json).
        to_return(body: [attributes_for(:movement, offenderNo: offender_no, toAgency: prison)].to_json)
  end

  context "when the team is associated with an LDU" do
    before do
      team = create(:team)

      stub_community_offender(offender_no, build(:community_data,
                                                 offenderManagers: [
                                                     build(:community_offender_manager,
                                                           team: { code: team.code,
                                                                   localDeliveryUnit: { code: team.local_divisional_unit.code } })]))
    end

    include_examples "imports the Delius spreadsheet and creates case information"
  end

  context 'when importing an Excel spreadsheet' do
    before do
      stub_const("Net::IMAP", MockIMAP)
      stub_const("Mail", MockMailMessage)

      ENV['DELIUS_EMAIL_FOLDER'] = delius_email_folder
      ENV['DELIUS_XLSX_PASSWORD'] = 'secret'
    end

    context "when the team is not associated with an LDU" do
      let(:delius_email_folder) {  'delius_import_feature' }

      before do
        team = build(:team, code: 'A')
        team.local_divisional_unit = nil
        team.save(validate: false)
        create(:local_divisional_unit, code: 'N01TRF')
      end

      it "does not attempt to process the active team as if it were a shadow team" do
        expect(Rails.logger).not_to receive(:error)
        DeliusImportJob.perform_now
      end
    end

    context "when the shadow team is not associated with an active team" do
      let(:delius_email_folder) {  'delius_import_feature_shadow' }

      before do
        local_divisional_unit = create(:local_divisional_unit, code: 'LDU1')
        team = build(:team, code: 'A', name: 'NPS - Team 1')
        team.shadow_code = nil
        team.local_divisional_unit = local_divisional_unit
        team.save!
      end

      it "does not attempt to process the shadow team as if it were an active team" do
        expect(Rails.logger).not_to receive(:error)
        DeliusImportJob.perform_now
      end
    end
  end
end
