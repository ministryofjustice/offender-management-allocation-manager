require "rails_helper"

describe HandoverFollowUpJob do
  let(:prison) { Prison.find_by(code: "LEI") || create(:prison, code: "LEI") }
  let(:local_delivery_unit) { FactoryBot.create(:local_delivery_unit, email_address: "ldu@email.com") }
  let(:mailer_double) { double("CommunityMailer", deliver_later: true) }

  before do
    stub_auth_token
    stub_offenders_for_prison(prison.code, [build(:nomis_offender, prisonerNumber: nomis_offender_id)])
    stub_poms(prison.code, [
      build(:pom, :prison_officer, emails: []),
    ])

    allow(CommunityMailer).to receive(:with).and_return(
      double("CommunityMailer", urgent_pipeline_to_community: mailer_double)
    )
  end

  def expect_to_have_sent_email_to(offender)
    expect(CommunityMailer).to have_received(:with).with(include(nomis_offender_id: offender.nomis_offender_id, ldu_email: "ldu@email.com"))
    expect(mailer_double).to have_received(:deliver_later)
  end

  def expect_not_to_have_sent_email_to(offender)
    expect(CommunityMailer).not_to have_received(:with).with(include(nomis_offender_id: offender.nomis_offender_id))
  end

  context "when the offender is at an active prison and handover date was a week ago" do
    let(:nomis_offender_id) { 'G7266VD' }

    it "sends the follow up email to that offender" do
      valid_offender = FactoryBot.create(:offender, nomis_offender_id:)
      FactoryBot.create(:calculated_handover_date, start_date: Time.zone.today - 1.week, offender: valid_offender)
      FactoryBot.create(:case_information, local_delivery_unit:, offender: valid_offender)
      FactoryBot.create(:allocation_history, nomis_offender_id: valid_offender.nomis_offender_id, prison: "LEI", primary_pom_nomis_id: "486154")

      described_class.new.perform(local_delivery_unit)

      expect_to_have_sent_email_to valid_offender
    end
  end

  context "when the offender has no handover date" do
    let(:nomis_offender_id) { 'G7260UD' }

    it "does not send the follow up email to that offender" do
      offender_without_a_handover_date = FactoryBot.create(:offender, nomis_offender_id:)
      FactoryBot.create(:case_information, local_delivery_unit:, offender: offender_without_a_handover_date)
      FactoryBot.create(:allocation_history, nomis_offender_id: offender_without_a_handover_date.nomis_offender_id, prison: "LEI", primary_pom_nomis_id: "486154")

      described_class.new.perform(local_delivery_unit)

      expect_not_to_have_sent_email_to offender_without_a_handover_date
    end
  end

  context "when the offender has a handover date in the future" do
    let(:nomis_offender_id) { 'G5241UH' }

    it "does not send the follow up email to that offender" do
      offender_with_a_handover_in_future = FactoryBot.create(:offender, nomis_offender_id:)
      FactoryBot.create(:calculated_handover_date, start_date: 1.week.from_now, offender: offender_with_a_handover_in_future)
      FactoryBot.create(:case_information, local_delivery_unit:, offender: offender_with_a_handover_in_future)
      FactoryBot.create(:allocation_history, nomis_offender_id: offender_with_a_handover_in_future.nomis_offender_id, prison: "LEI", primary_pom_nomis_id: "486154")

      described_class.new.perform(local_delivery_unit)

      expect_not_to_have_sent_email_to offender_with_a_handover_in_future
    end
  end

  context "when the offender is at a prison that is not active" do
    let(:nomis_offender_id) { 'G0918GN' }

    it "does not send the follow up email to that offender" do
      offender_without_an_active_prison = FactoryBot.create(:offender, nomis_offender_id:)
      FactoryBot.create(:calculated_handover_date, start_date: 1.week.from_now, offender: offender_without_an_active_prison)
      FactoryBot.create(:case_information, local_delivery_unit:, offender: offender_without_an_active_prison)

      described_class.new.perform(local_delivery_unit)

      expect_not_to_have_sent_email_to offender_without_an_active_prison
    end
  end

  context "when the offender is at another LDU" do
    let(:nomis_offender_id) { 'G0918GN' }

    it "does not send the follow up email to that offender" do
      a_different_ldu = FactoryBot.create(:local_delivery_unit, email_address: "a-different-ldu@email.com")
      offender_at_a_different_ldu = FactoryBot.create(:offender, nomis_offender_id:)
      FactoryBot.create(:calculated_handover_date, start_date: 1.week.from_now, offender: offender_at_a_different_ldu)
      FactoryBot.create(:case_information, local_delivery_unit: a_different_ldu, offender: offender_at_a_different_ldu)

      described_class.new.perform(local_delivery_unit)

      expect_not_to_have_sent_email_to offender_at_a_different_ldu
    end
  end
end
