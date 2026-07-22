# frozen_string_literal: true

class DebouncedRecalculateHandoverDateJob < ApplicationJob
  queue_as :debounce

  # Best-effort only: if this fails the daily sweep will catch up within 24h
  sidekiq_options retry: 0

  def perform(nomis_offender_id, debounce_key:, debounce_token:)
    return unless debounce_token_match?(nomis_offender_id, debounce_key, debounce_token)

    job = RecalculateHandoverDateJob.perform_later(nomis_offender_id, trigger_method: 'event')

    logger.info(
      "job=debounced_recalculate_handover_date_job,event=enqueued,nomis_offender_id=#{nomis_offender_id},job_id=#{job.job_id}"
    )
  end

private

  def debounce_token_match?(nomis_offender_id, debounce_key, debounce_token)
    cached_token = Rails.cache.read(debounce_key)
    return true if cached_token.nil? || cached_token == debounce_token

    logger.info("job=debounced_recalculate_handover_date_job,event=skipped,nomis_offender_id=#{nomis_offender_id}")
    false
  rescue StandardError => e
    # If cache is unavailable for whatever reason, skip rather than risk running
    # without debounce protection, as the daily sweep will catch up within 24h
    logger.warn("job=debounced_recalculate_handover_date_job,event=cache_error,nomis_offender_id=#{nomis_offender_id}|#{e.message}")
    false
  end
end
