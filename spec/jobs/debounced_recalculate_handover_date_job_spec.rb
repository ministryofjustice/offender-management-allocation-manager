# frozen_string_literal: true

RSpec.describe DebouncedRecalculateHandoverDateJob, type: :job do
  let(:nomis_offender_id) { 'A1234BC' }
  let(:debounce_key) { "domain_events:prisoner_updated_handover:#{nomis_offender_id}" }
  let(:job_logger) { instance_double(ActiveSupport::Logger, info: nil, warn: nil) }

  let(:enqueued_job) { instance_double(RecalculateHandoverDateJob, job_id: 'job-123') }

  before do
    allow(RecalculateHandoverDateJob).to receive(:perform_later).and_return(enqueued_job)
  end

  context 'when the offender has an existing calculated handover date' do
    it 'enqueues RecalculateHandoverDateJob when the debounce token matches' do
      debounce_token = SecureRandom.uuid
      Rails.cache.write(debounce_key, debounce_token)

      described_class.perform_now(nomis_offender_id, debounce_key:, debounce_token:)

      expect(RecalculateHandoverDateJob).to have_received(:perform_later).with(nomis_offender_id)
    end

    it 'enqueues RecalculateHandoverDateJob when the debounce key is missing or expired' do
      debounce_token = SecureRandom.uuid

      described_class.perform_now(nomis_offender_id, debounce_key:, debounce_token:)

      expect(RecalculateHandoverDateJob).to have_received(:perform_later).with(nomis_offender_id)
    end

    it 'skips when the debounce token does not match the cache' do
      Rails.cache.write(debounce_key, SecureRandom.uuid)
      debounce_token = SecureRandom.uuid

      described_class.perform_now(nomis_offender_id, debounce_key:, debounce_token:)

      expect(RecalculateHandoverDateJob).not_to have_received(:perform_later)
    end

    it 'skips and logs a warning when reading from the cache raises an error' do
      debounce_token = SecureRandom.uuid
      allow(Rails.cache).to receive(:read).with(debounce_key).and_raise(StandardError, 'boom')
      allow_any_instance_of(described_class).to receive(:logger).and_return(job_logger)

      described_class.perform_now(nomis_offender_id, debounce_key:, debounce_token:)

      expect(RecalculateHandoverDateJob).not_to have_received(:perform_later)
      expect(job_logger).to have_received(:warn).with(
        'job=debounced_recalculate_handover_date_job,event=cache_error,nomis_offender_id=A1234BC|boom'
      )
    end
  end
end
