# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PushHandoverDatesToDeliusJob, :disable_push_to_delius, type: :job do
  include MutexHelper
  let(:nomis_offender_id) { 'G4281GV' }

  before do
    stub_auth_token
  end

  context 'when mutex lock is not present' do
    let!(:handover_date) {
      create(:calculated_handover_date, offender: build(:offender, nomis_offender_id: nomis_offender_id))
    }

    it 'pushes data to delius without mutex lock' do
      described_class.perform_now handover_date
      expect(lock_exists(ProcessDeliusDataJob::JOB_NAME, nomis_offender_id)).to be(false)
    end

    it 'creates mutex lock when status 400 is returned from delius' do
      allow(HmppsApi::CommunityApi).to receive(:set_handover_dates).and_raise(Faraday::BadRequestError.new("error"))
      expect(lock_exists(ProcessDeliusDataJob::JOB_NAME, nomis_offender_id)).to be(false)
      described_class.perform_now handover_date
      expect(lock_exists(ProcessDeliusDataJob::JOB_NAME, nomis_offender_id)).to be(true)
    end
  end

  context 'when mutex lock is present' do
    let!(:handover_date) {
      create(:calculated_handover_date, offender: build(:offender, nomis_offender_id: nomis_offender_id))
    }

    it 'removes lock when handover date is recalculated' do
      create_lock(ProcessDeliusDataJob::JOB_NAME, nomis_offender_id)
      described_class.perform_now handover_date
      expect(lock_exists(ProcessDeliusDataJob::JOB_NAME, nomis_offender_id)).to be(false)
    end
  end
end
