require "rails_helper"

describe HandoverFollowUpJob, vcr: { cassette_name: "prison_api/handover_follow_up_email" } do
  before { allow(CommunityMailer).to receive(:with).and_return(double("CommunityMailer", urgent_pipeline_to_community: nil)) }

  around do |example|
    cassettes = [
      { name: 'prison_api/offender_api' },
      { name: 'prison_api/pom_api_list_spec' },
      { name: 'prison_api/elite2_staff_api_get_email' }
    ]
    VCR.use_cassettes(cassettes) do
      example.run
    end
  end

  def expect_to_have_sent_email_to(offender)
    expect(CommunityMailer).to have_received(:with).with(include(nomis_offender_id: offender.nomis_offender_id, ldu_email: "ldu@email.com"))
  end

  def expect_not_to_have_sent_email_to(offender)
    expect(CommunityMailer).not_to have_received(:with).with(include(nomis_offender_id: offender.nomis_offender_id))
  end

  let(:local_delivery_unit) { FactoryBot.create(:local_delivery_unit, email_address: "ldu@email.com") }

  context "when the offender is at an active prison and handover date was a week ago" do
    it "sends the follow up email to that offender" do
      valid_offender = FactoryBot.create(:offender, nomis_offender_id: "G7266VD")
      FactoryBot.create(:calculated_handover_date, start_date: Time.zone.today - 1.week, offender: valid_offender)
      FactoryBot.create(:case_information, local_delivery_unit:, offender: valid_offender)
      FactoryBot.create(:allocation_history, nomis_offender_id: valid_offender.nomis_offender_id, prison: "LEI", primary_pom_nomis_id: "485982")

      described_class.new.perform(local_delivery_unit)

      expect_to_have_sent_email_to valid_offender
    end
  end

  context "when the offender has no handover date" do
    it "does not send the follow up email to that offender" do
      offender_without_a_handover_date = FactoryBot.create(:offender, nomis_offender_id: "G7260UD")
      FactoryBot.create(:case_information, local_delivery_unit:, offender: offender_without_a_handover_date)
      FactoryBot.create(:allocation_history, nomis_offender_id: offender_without_a_handover_date.nomis_offender_id, prison: "LEI", primary_pom_nomis_id: "485982")

      described_class.new.perform(local_delivery_unit)

      expect_not_to_have_sent_email_to offender_without_a_handover_date
    end
  end

  context "when the offender has a handover date in the future" do
    it "does not send the follow up email to that offender" do
      offender_with_a_handover_in_future = FactoryBot.create(:offender, nomis_offender_id: "G5241UH")
      FactoryBot.create(:calculated_handover_date, start_date: 1.week.from_now, offender: offender_with_a_handover_in_future)
      FactoryBot.create(:case_information, local_delivery_unit:, offender: offender_with_a_handover_in_future)
      FactoryBot.create(:allocation_history, nomis_offender_id: offender_with_a_handover_in_future.nomis_offender_id, prison: "LEI", primary_pom_nomis_id: "485982")

      described_class.new.perform(local_delivery_unit)

      expect_not_to_have_sent_email_to offender_with_a_handover_in_future
    end
  end

  context "when the offender is at a prison that is not active" do
    it "does not send the follow up email to that offender" do
      offender_without_an_active_prison = FactoryBot.create(:offender, nomis_offender_id: "G0918GN")
      FactoryBot.create(:calculated_handover_date, start_date: 1.week.from_now, offender: offender_without_an_active_prison)
      FactoryBot.create(:case_information, local_delivery_unit:, offender: offender_without_an_active_prison)

      described_class.new.perform(local_delivery_unit)

      expect_not_to_have_sent_email_to offender_without_an_active_prison
    end
  end

  context "when the offender is at another LDU" do
    it "does not send the follow up email to that offender" do
      a_different_ldu = FactoryBot.create(:local_delivery_unit, email_address: "a-different-ldu@email.com")
      offender_at_a_different_ldu = FactoryBot.create(:offender, nomis_offender_id: "G0918GN")
      FactoryBot.create(:calculated_handover_date, start_date: 1.week.from_now, offender: offender_at_a_different_ldu)
      FactoryBot.create(:case_information, local_delivery_unit: a_different_ldu, offender: offender_at_a_different_ldu)

      described_class.new.perform(local_delivery_unit)

      expect_not_to_have_sent_email_to offender_at_a_different_ldu
    end
  end
end
