require 'rails_helper'
require 'support/lib/mock_imap'
require 'support/lib/mock_mail'
require 'delius_import_job'

feature "Delius import feature" do
  let(:stub_auth_host) { Rails.configuration.nomis_oauth_host }
  let(:stub_api_host) { "#{stub_auth_host}/elite2api/api" }
  let(:offender_no) { "GCA2H2A" }
  let(:prison) { "LEI" }
  let(:booking_id) { 754_207 }
  let(:offenders) {
    [{
      "bookingId": booking_id,
      "offenderNo": offender_no,
      "dateOfBirth": "1985-03-19",
      "agencyId": prison,
      "imprisonmentStatus": "DET"
    }]
  }
  let(:bookings) {
    [{  "bookingId": booking_id,
        "offenderNo": offender_no,
        "agencyLocationId": prison,
        "sentenceDetail": { "homeDetentionCurfewEligibilityDate": "2011-11-07",
                            "sentenceStartDate": "2009-02-08"
                          }
    }]
  }

  before do
    signin_spo_user

    stub_request(:post, "#{stub_auth_host}/auth/oauth/token").
      with(query: { grant_type: 'client_credentials' }).
        to_return(status: 200, body: {}.to_json)

    stub_offender(offender_no, booking_number: booking_id, imprisonment_status: 'DET', dob: "1985-03-19")

    stub_offenders_for_prison("LEI", offenders, bookings)

    stub_request(:post, "#{stub_api_host}/movements/offenders?latestOnly=false&movementTypes=TRN").
      with(body: [offender_no].to_json).
        to_return(status: 200, body: [{ offenderNo: offender_no, toAgency: prison }].to_json)

    stub_const("Net::IMAP", MockIMAP)

    stub_const("Mail", MockMailMessage)

    ENV['DELIUS_EMAIL_FOLDER'] = 'delius_import_feature'
    ENV['DELIUS_XLSX_PASSWORD'] = 'secret'
  end

  context "when the team is associated with an LDU" do
    before { create(:team, code: 'A') }

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

  context "when the team is not associated with an LDU" do
    before do
      team = build(:team, code: 'A')
      team.local_divisional_unit = nil
      team.save(validate: false)
      create(:local_divisional_unit, code: 'N01TRF')
    end

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
end
