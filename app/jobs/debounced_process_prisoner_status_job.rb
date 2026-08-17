# frozen_string_literal: true

class DebouncedProcessPrisonerStatusJob < ApplicationJob
  queue_as :debounce

  # Debounce token becomes stale quickly, so long retry cycles are pointless
  sidekiq_options retry: 3

  def perform(nomis_offender_id, debounce_key:, debounce_token:)
    return unless debounce_token_match?(nomis_offender_id, debounce_key, debounce_token)

    job = ProcessPrisonerStatusJob.perform_later(nomis_offender_id, trigger_method: :event)

    logger.info(
      "job=debounced_process_prisoner_status_job,event=enqueued,nomis_offender_id=#{nomis_offender_id},job_id=#{job.job_id}"
    )
  end

private

  def debounce_token_match?(nomis_offender_id, debounce_key, debounce_token)
    cached_token = Rails.cache.read(debounce_key)
    return true if cached_token.nil? || cached_token == debounce_token

    logger.info("job=debounced_process_prisoner_status_job,event=skipped,nomis_offender_id=#{nomis_offender_id}")
    false
  rescue StandardError => e
    # If cache is unavailable for whatever reason, we proceed as if there is
    # no debounce mechanism rather than risk too many skipped jobs
    logger.warn("job=debounced_process_prisoner_status_job,event=cache_error,nomis_offender_id=#{nomis_offender_id}|#{e.message}")
    true
  end
end
