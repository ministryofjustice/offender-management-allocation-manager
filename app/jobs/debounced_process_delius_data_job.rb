# frozen_string_literal: true

class DebouncedProcessDeliusDataJob < ApplicationJob
  queue_as :debounce

  def perform(crn_number, event_type:, debounce_key:, debounce_token:)
    return unless debounce_token_match?(crn_number, debounce_key, debounce_token)

    ProcessDeliusDataJob.perform_now(
      crn_number, identifier_type: :crn, trigger_method: :event, event_type:
    )
  end

private

  def debounce_token_match?(crn_number, debounce_key, debounce_token)
    cached_token = Rails.cache.read(debounce_key)
    return true if cached_token.nil? || cached_token == debounce_token

    logger.info("job=debounced_process_delius_data_job,event=skipped,crn=#{crn_number}")
    false
  rescue StandardError => e
    # If cache is unavailable for whatever reason, we proceed as if there is
    # no debounce mechanism rather than risk too many skipped jobs
    logger.warn("job=debounced_process_delius_data_job,event=cache_error,crn=#{crn_number}|#{e.message}")
    true
  end
end
