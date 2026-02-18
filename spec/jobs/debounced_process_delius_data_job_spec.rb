# frozen_string_literal: true

RSpec.describe DebouncedProcessDeliusDataJob, type: :job do
  let(:crn) { 'X12345' }
  let(:debounce_key) { "domain_events:probation_change:#{crn}" }
  let(:event_type) { 'OFFENDER_DETAILS_CHANGED' }

  let(:job_logger) { instance_double(ActiveSupport::Logger, info: nil, warn: nil) }

  before do
    allow(ProcessDeliusDataJob).to receive(:perform_now)
    allow_any_instance_of(described_class).to receive(:logger).and_return(job_logger)
  end

  it 'runs the job when the debounce token matches the cache' do
    debounce_token = SecureRandom.uuid
    Rails.cache.write(debounce_key, debounce_token)

    described_class.perform_now(
      crn,
      event_type:,
      debounce_key:,
      debounce_token:
    )

    expect(ProcessDeliusDataJob).to have_received(:perform_now).with(
      crn,
      identifier_type: :crn,
      trigger_method: :event,
      event_type:
    )
  end

  it 'skips the job when the debounce token does not match the cache' do
    Rails.cache.write(debounce_key, SecureRandom.uuid)
    debounce_token = SecureRandom.uuid

    described_class.perform_now(
      crn,
      event_type:,
      debounce_key:,
      debounce_token:
    )

    expect(job_logger).to have_received(:info).with(
      "job=debounced_process_delius_data_job,event=skipped,crn=#{crn}"
    )
    expect(ProcessDeliusDataJob).not_to have_received(:perform_now)
  end

  it 'do not skip the job when reading from the cache raises an error' do
    debounce_token = SecureRandom.uuid
    allow(Rails.cache).to receive(:read).with(debounce_key).and_raise(StandardError, 'boom')

    described_class.perform_now(
      crn,
      event_type:,
      debounce_key:,
      debounce_token:
    )

    expect(job_logger).to have_received(:warn).with(
      "job=debounced_process_delius_data_job,event=cache_error,crn=#{crn}|boom"
    )
    expect(ProcessDeliusDataJob).to have_received(:perform_now)
  end
end
