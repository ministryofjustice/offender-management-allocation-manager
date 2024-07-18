require 'rails_helper'

describe "Emails sent are logged in EmailHistory" do
  before { stub_const('Notifications::Client', double(send_email: {}).as_null_object) }

  let(:offender) do
    create(:offender).then do |offender|
      double(nomis_offender_id: offender.nomis_offender_id, full_name: "Test Offender")
    end
  end
  let(:prison) { create(:prison) }

  describe "PomMailer responsibility_override" do
    it "is logged" do
      expect {
        perform_enqueued_jobs do
          PomMailer.with(
            prisoner_name: "Test Offender",
            prisoner_number: offender.nomis_offender_id,
            message: "Really good reason",
            prison_name: prison.name,
            email: "test1@email.com"
          ).responsibility_override.deliver_later
        end
      }.to change {
        EmailHistory.responsibility_override.where(
          nomis_offender_id: offender.nomis_offender_id,
          prison: prison.code,
          email: "test1@email.com",
        ).count
      }.from(0).to(1)
    end
  end

  describe "CommunityMailer open_prison_supporting_com_needed" do
    it "is logged" do
      expect {
        perform_enqueued_jobs do
          CommunityMailer.with(
            prisoner_name: "Test Offender",
            prisoner_number: offender.nomis_offender_id,
            prisoner_crn: "CRN123",
            prison_name: prison.name,
            ldu_email: "test1@email.com"
          ).open_prison_supporting_com_needed.deliver_later
        end
      }.to change {
        EmailHistory.open_prison_supporting_com_needed.where(
          nomis_offender_id: offender.nomis_offender_id,
          prison: prison.code,
          email: "test1@email.com",
        ).count
      }.from(0).to(1)
    end
  end

  describe "CommunityMailer urgent_pipeline_to_community" do
    it "is logged" do
      expect {
        perform_enqueued_jobs do
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
          ).urgent_pipeline_to_community.deliver_later
        end
      }.to change {
        EmailHistory.urgent_pipeline_to_community.where(
          nomis_offender_id: offender.nomis_offender_id,
          prison: prison.code,
          email: "test1@email.com",
        ).count
      }.from(0).to(1)
    end
  end
end
