RSpec.describe Handover::HandoverEmail do
  let(:nomis_offender_id) { "TEST_NOMS_NO" }
  let(:pom_id) { "TEST_STAFF_ID_1" }
  let(:pom_email) { "pom@example.com" }
  let(:default_args) { { email: pom_email, param1: "value1", param2: "value2" } }
  let(:final_mailer_args) { default_args.merge(nomis_offender_id: nomis_offender_id) }

  before do
    allow(HandoverMailer).to receive(:upcoming_handover_window)
    allow(OffenderEmailSent).to receive_messages(find_by: [], create!: nil)
    allow(OffenderEmailOptOut).to receive_messages(find_by: [])
  end

  describe "::deliver_if_deliverable" do
    let(:handover_email_type) { :upcoming_handover_window }
    let(:mailer) { double :mailer, deliver_later: nil }

    before do
      allow(HandoverMailer).to receive_messages(handover_email_type => mailer)
    end

    describe "when not opted out and not already sent" do
      before do
        described_class.deliver_if_deliverable(handover_email_type, nomis_offender_id, pom_id, default_args)
      end

      it "sends the email" do
        aggregate_failures do
          expect(HandoverMailer).to have_received(handover_email_type).with(final_mailer_args)
          expect(mailer).to have_received(:deliver_later)
        end
      end

      it "creates sent record" do
        expect(OffenderEmailSent).to have_received(:create!).with(nomis_offender_id: nomis_offender_id,
                                                                  staff_member_id: pom_id,
                                                                  offender_email_type: handover_email_type)
      end
    end

    describe "when opted out" do
      before do
        allow(OffenderEmailOptOut).to receive(:find_by).with(staff_member_id: pom_id,
                                                             offender_email_type: handover_email_type)
                                                       .and_return([anything])
        described_class.deliver_if_deliverable(handover_email_type, nomis_offender_id, pom_id, default_args)
      end

      it "does not send the email" do
        aggregate_failures do
          expect(HandoverMailer).not_to have_received(handover_email_type)
          expect(mailer).not_to have_received(:deliver_later)
        end
      end

      it "does not create sent record" do
        expect(OffenderEmailSent).not_to have_received(:create!)
      end
    end

    describe "when already sent" do
      before do
        allow(OffenderEmailSent).to receive(:find_by).with(nomis_offender_id: nomis_offender_id,
                                                           staff_member_id: pom_id,
                                                           offender_email_type: handover_email_type)
                                                       .and_return([anything])
        described_class.deliver_if_deliverable(handover_email_type, nomis_offender_id, pom_id, default_args)
      end

      it "does not send the email" do
        aggregate_failures do
          expect(HandoverMailer).not_to have_received(handover_email_type)
          expect(mailer).not_to have_received(:deliver_later)
        end
      end

      it "does not create sent record" do
        expect(OffenderEmailSent).not_to have_received(:create!)
      end
    end

    it "works with other email types" do
      allow(HandoverMailer).to receive_messages(handover_date: double.as_null_object)
      described_class.deliver_if_deliverable(:handover_date, nomis_offender_id, pom_id, email: pom_email)
      expect(HandoverMailer).to have_received(:handover_date)
    end
  end
end
