# frozen_string_literal: true

RSpec.describe DebouncedProcessPrisonerStatusJob, type: :job do
  let(:nomis_offender_id) { 'A1234BC' }
  let(:debounce_key) { "domain_events:prisoner_updated_status:#{nomis_offender_id}" }
  let(:job_logger) { instance_double(ActiveSupport::Logger, info: nil, warn: nil) }
  let(:enqueued_job) { instance_double(ActiveJob::Base, job_id: 'job-123') }

  before do
    allow(ProcessPrisonerStatusJob).to receive(:perform_later).and_return(enqueued_job)
    allow_any_instance_of(described_class).to receive(:logger).and_return(job_logger)
  end

  it 'enqueues ProcessPrisonerStatusJob when the debounce token matches' do
    debounce_token = SecureRandom.uuid
    Rails.cache.write(debounce_key, debounce_token)

    described_class.perform_now(nomis_offender_id, debounce_key:, debounce_token:)

    expect(ProcessPrisonerStatusJob).to have_received(:perform_later).with(nomis_offender_id, trigger_method: :event)
    expect(job_logger).to have_received(:info).with(
      "job=debounced_process_prisoner_status_job,event=enqueued,nomis_offender_id=#{nomis_offender_id},job_id=job-123"
    )
  end

  it 'skips when the debounce token does not match the cache' do
    Rails.cache.write(debounce_key, SecureRandom.uuid)
    debounce_token = SecureRandom.uuid

    described_class.perform_now(nomis_offender_id, debounce_key:, debounce_token:)

    expect(job_logger).to have_received(:info).with(
      "job=debounced_process_prisoner_status_job,event=skipped,nomis_offender_id=#{nomis_offender_id}"
    )
    expect(ProcessPrisonerStatusJob).not_to have_received(:perform_later)
  end

  it 'enqueues when the debounce key is missing or expired' do
    debounce_token = SecureRandom.uuid

    described_class.perform_now(nomis_offender_id, debounce_key:, debounce_token:)

    expect(ProcessPrisonerStatusJob).to have_received(:perform_later).with(nomis_offender_id, trigger_method: :event)
    expect(job_logger).to have_received(:info).with(
      "job=debounced_process_prisoner_status_job,event=enqueued,nomis_offender_id=#{nomis_offender_id},job_id=job-123"
    )
  end

  it 'does not skip when reading cache raises an error' do
    debounce_token = SecureRandom.uuid
    allow(Rails.cache).to receive(:read).with(debounce_key).and_raise(StandardError, 'boom')

    described_class.perform_now(nomis_offender_id, debounce_key:, debounce_token:)

    expect(job_logger).to have_received(:warn).with(
      "job=debounced_process_prisoner_status_job,event=cache_error,nomis_offender_id=#{nomis_offender_id}|boom"
    )
    expect(ProcessPrisonerStatusJob).to have_received(:perform_later).with(nomis_offender_id, trigger_method: :event)
  end
end
