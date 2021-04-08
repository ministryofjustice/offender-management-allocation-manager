require 'rails_helper'

RSpec.describe EmailHistory, type: :model do
  let(:offender_id) { 'A3434LK' }

  describe '.sent_within_current_sentence' do
    subject { described_class.sent_within_current_sentence(offender, event) }

    let(:offender) { build(:offender, sentence: build(:sentence_detail, sentenceStartDate: 7.days.ago)) }
    let(:some_other_offender) { build(:offender) }

    let(:event) { EmailHistory::OPEN_PRISON_COMMUNITY_ALLOCATION }
    let(:some_other_event) { EmailHistory::AUTO_EARLY_ALLOCATION }

    let(:case_info) { create(:case_information, nomis_offender_id: offender.offender_no) }

    # An old email sent before the offender's current sentence
    let!(:old_email) {
      create(:email_history,
             case_information: case_info,
             event: event,
             created_at: 1.year.ago)
    }

    # An email sent within the offender's current sentence
    let!(:recent_email) {
      create(:email_history,
             case_information: case_info,
             event: event,
             created_at: 5.days.ago)
    }

    # A recent email but for a different event
    let!(:recent_email_different_event) {
      create(:email_history,
             case_information: case_info,
             event: some_other_event,
             created_at: 5.days.ago)
    }

    # A recent email sent for a different offender
    let!(:recent_email_different_offender) {
      create(:email_history,
             case_information: build(:case_information, nomis_offender_id: some_other_offender.offender_no),
             event: event,
             created_at: 5.days.ago)
    }

    it "returns emails for the specified event, sent within the offender's current sentence" do
      expect(subject).to eq([recent_email])
    end
  end
end
