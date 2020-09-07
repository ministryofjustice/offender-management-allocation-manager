require 'rails_helper'
require 'support/lib/mock_imap'
require 'support/lib/mock_mail'
require 'delius_import_job'

RSpec.shared_examples "imports the Delius spreadsheet and creates case information" do
  it "imports the Delius spreadsheet and creates case information" do
    visit prison_summary_pending_path(prison)
    expect(page).to have_content("Add missing information")
    expect(page).to have_content(offender_no)

    DeliusImportJob.perform_now

    reload_page
    expect(page).to have_content("Add missing information")
    expect(page).not_to have_content(offender_no)

    visit prison_summary_unallocated_path(prison)
    expect(page).to have_content("Make allocations")
    expect(page).to have_content(offender_no)
  end
end

feature "Delius import feature" do
  let(:stub_auth_host) { Rails.configuration.nomis_oauth_host }
  let(:stub_api_host) { "#{Rails.configuration.prison_api_host}/api" }
  let(:offender_no) { "GCA2H2A" }
  let(:prison) { "LEI" }
  let(:booking_id) { 754_207 }
  let(:offender) { build(:nomis_offender, offenderNo: offender_no, imprisonmentStatus: 'DET', dateOfBirth: "1985-03-19") }

  before do
    signin_spo_user

    stub_auth_token
    stub_request(:get, "#{ApiHelper::T3}/users/MOIC_POM").
      to_return(body: { 'staffId': 1 }.to_json)
    stub_pom_emails(1, [])

    stub_offender(offender)

    stub_offenders_for_prison("LEI", [offender])

    stub_request(:post, "#{stub_api_host}/movements/offenders?latestOnly=false&movementTypes=TRN").
      with(body: [offender_no].to_json).
        to_return(body: [attributes_for(:movement, offenderNo: offender_no, toAgency: prison)].to_json)

    stub_const("Net::IMAP", MockIMAP)

    stub_const("Mail", MockMailMessage)

    ENV['DELIUS_XLSX_PASSWORD'] = 'secret'
  end

  context "when the team is associated with an LDU", :js do
    before do
      ENV['DELIUS_EMAIL_FOLDER'] = 'delius_import_feature'
      create(:team, code: 'A', name: 'NPS - Team 1')
    end

    include_examples "imports the Delius spreadsheet and creates case information"
  end

  context "when the team is not associated with an LDU" do
    before do
      ENV['DELIUS_EMAIL_FOLDER'] = 'delius_import_feature'
      team = build(:team, code: 'A')
      team.local_divisional_unit = nil
      team.save(validate: false)
      create(:local_divisional_unit, code: 'N01TRF')
    end

    include_examples "imports the Delius spreadsheet and creates case information"

    it "does not attempt to process the active team as if it were a shadow team" do
      expect(Rails.logger).not_to receive(:error)
      DeliusImportJob.perform_now
    end
  end

  context "when the shadow team is not associated with an active team" do
    before do
      ENV['DELIUS_EMAIL_FOLDER'] = 'delius_import_feature_shadow'
      local_divisional_unit = create(:local_divisional_unit, code: 'LDU1')
      team = build(:team, code: 'A', name: 'NPS - Team 1')
      team.shadow_code = nil
      team.local_divisional_unit = local_divisional_unit
      team.save
    end

    include_examples "imports the Delius spreadsheet and creates case information"

    it "does not attempt to process the shadow team as if it were an active team" do
      expect(Rails.logger).not_to receive(:error)
      DeliusImportJob.perform_now
    end
  end
end
