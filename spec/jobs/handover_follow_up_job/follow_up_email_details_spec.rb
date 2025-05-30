require "rails_helper"

describe HandoverFollowUpJob::FollowUpEmailDetails do
  let(:prison) { Prison.find_by(code: "LEI") || create(:prison, code: "LEI") }
  let(:handover_start_date) { 1.week.from_now }
  let(:handover_date) { 2.weeks.from_now }
  let(:indeterminate_sentence) { false }
  let(:offender) do
    double("offender",
           offender_no: "OFF1",
           prison_id: prison.id,
           indeterminate_sentence?: indeterminate_sentence,
           full_name: "Nevis, Granville",
           crn: "CRN123",
           ldu_email_address: "ldu@email.com",
           handover_start_date:,
           handover_date:
          ).as_null_object
  end

  describe "the details used in sending the CommunityMailer email" do
    before do
      stub_auth_token
      stub_poms(prison.code, [build(:pom, staffId: 486_154, firstName: 'MOIC', lastName: 'POM', emails: ['test@example.com'])])
    end

    it "includes basic details regardless of allocation or sentence type" do
      details = described_class.for(offender:)

      expect(details).to match(
        ldu_email: "ldu@email.com",
        nomis_offender_id: "OFF1",
        offender_crn: "CRN123",
        offender_name: "Nevis, Granville",
        pom_email: anything,
        pom_name: anything,
        prison: "Leeds (HMP)",
        responsibility_handover_date: handover_date,
        start_date: handover_start_date,
        sentence_type: anything
      )
    end

    context "when the offender has a POM allocated" do
      before { FactoryBot.create(:allocation_history, nomis_offender_id: offender.offender_no, prison: prison.code, primary_pom_nomis_id: "486154") }

      it "includes the POM details in the email" do
        details = described_class.for(offender:)

        expect(details).to include(
          pom_email: "test@example.com",
          pom_name: "Pom, Moic",
        )
      end
    end

    context "when the offender has a POM allocated but is not included in the list of POMs for that prison" do
      before { FactoryBot.create(:allocation_history, nomis_offender_id: offender.offender_no, prison: prison.code, primary_pom_nomis_id: "9999") }

      it "includes fallback POM details in the email" do
        details = described_class.for(offender:)

        expect(details).to include(
          pom_email: "unknown",
          pom_name: "unknown",
        )
      end
    end

    context "when the offender has no POM allocated" do
      it "does not include the POM details in the email" do
        details = described_class.for(offender:)

        expect(details).to include(
          pom_email: "n/a",
          pom_name: "This offender does not have an allocated POM",
        )
      end
    end

    context "when the offender sentence is determinate" do
      let(:indeterminate_sentence) { false }

      it "has 'Determinate' as the sentence type in the email" do
        details = described_class.for(offender:)

        expect(details).to include(sentence_type: "Determinate")
      end
    end

    context "when the offender sentence is indeterminate" do
      let(:indeterminate_sentence) { true }

      it "has 'Indeterminate' as the sentence type in the email" do
        details = described_class.for(offender:)

        expect(details).to include(sentence_type: "Indeterminate")
      end
    end
  end
end
