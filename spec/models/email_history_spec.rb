require 'rails_helper'

RSpec.describe EmailHistory, type: :model do
  let(:offender_id) { 'A3434LK' }

  describe '#welsh_open_prescoed' do
    before do
      create(:email_history, :welsh_prescoed_transfer, prison: PrisonService::PRESCOED_CODE, nomis_offender_id: offender_id, name: 'LDU Number 1', created_at: Time.zone.today - 14.months)
      create(:email_history, :welsh_prescoed_transfer, prison: PrisonService::PRESCOED_CODE, nomis_offender_id: offender_id, name: 'LDU Number 1', created_at: Time.zone.today - 3.months)
      create(:email_history, :auto_early_allocation, prison: 'LEI', nomis_offender_id: offender_id, name: 'LDU Number 3', created_at: Time.zone.today)
    end

    it 'returns all records relating to the event: WELSH_TRANSFER_TO_PRESCOED in descending order' do
      email_history = described_class.welsh_open_prescoed(offender_id)
      expect(email_history.count).to eq(2)
      expect(email_history.first.event).to eq(EmailHistory::OPEN_PRISON_COMMUNITY_ALLOCATION)
      expect(email_history.last.event).to eq(EmailHistory::OPEN_PRISON_COMMUNITY_ALLOCATION)
      expect(email_history.first.created_at).to be > email_history.last.created_at
    end
  end
end
