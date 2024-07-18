require 'rails_helper'

describe "Emails sent are logged in EmailHistory" do
  let(:offender) { double(nomis_offender_id: create(:offender).nomis_offender_id, full_name: "Test Offender") }
  let(:prison) { create(:prison) }
  let(:responsibility_override) do
    PomMailer.with(
      prisoner_name: "Test Offender",
      prisoner_number: offender.nomis_offender_id,
      message: "Really good reason",
      prison_name: prison.name,
      email: "test1@email.com"
    ).responsibility_override
  end
  let(:open_prison_supporting_com_needed) do
    CommunityMailer.with(
      prisoner_name: "Test Offender",
      prisoner_number: offender.nomis_offender_id,
      prisoner_crn: "CRN123",
      prison_name: prison.name,
      ldu_email: "test1@email.com"
    ).open_prison_supporting_com_needed
  end
  let(:urgent_pipeline_to_community) do
    CommunityMailer.with(
      offender_name: "Test Offender",
      nomis_offender_id: offender.nomis_offender_id,
      offender_crn: "CRN123",
      prison: prison.name,
      start_date: 3.weeks.ago,
      responsibility_handover_date: 2.weeks.ago,
      pom_name: "Mr POM",
      pom_email: "mr.pom@pom.com",
      ldu_email: "test1@email.com",
      sentence_type: "ISP"
    ).urgent_pipeline_to_community
  end
  let(:email_histories) do
    EmailHistory.where(
      nomis_offender_id: offender.nomis_offender_id,
      prison: prison.code,
      email: "test1@email.com",
    )
  end

  before { stub_const('Notifications::Client', double(send_email: {}).as_null_object) }
  around { |example| perform_enqueued_jobs { example.run } }

  actions = [
    :responsibility_override,
    :open_prison_supporting_com_needed,
    :urgent_pipeline_to_community
  ]
  actions.each do |action|
    it "is logs action #{action} appropriately" do
      mailer = send(action)
      expect { mailer.deliver_later }
        .to change { email_histories.where(event: action).count }.from(0).to(1)
    end
  end
end
