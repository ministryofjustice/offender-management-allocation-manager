# frozen_string_literal: true

class ProcessTierChangeJob < ApplicationJob
  queue_as :deferred

  # Transient errors bubble up from `TieringApi` and are retried by Sidekiq
  # 5 retries (~10 min with exp backoff) is sufficient for transient issues
  sidekiq_options retry: 5

  def perform(crn, event_type:)
    result = TierUpdateService.call(crn:, audit_tags: ['handler'])

    case result.status
    when :updated
      logger.info "event=process_tier_change_job_success,event_type=#{event_type}," \
                  "version=#{result.version},crn=#{crn},old_tier=#{result.old_tier},new_tier=#{result.new_tier}"
    when :invalid_tier
      logger.error "event=process_tier_change_job_invalid_tier,event_type=#{event_type}," \
                   "version=#{result.version},crn=#{crn},old_tier=#{result.old_tier},new_tier=#{result.new_tier}|#{result.errors}"
    when :update_failed
      logger.error "event=process_tier_change_job_failure,event_type=#{event_type}," \
                   "version=#{result.version},crn=#{crn},old_tier=#{result.old_tier},new_tier=#{result.new_tier}|#{result.errors}"
    when :tier_api_failed
      logger.warn "event=process_tier_change_job_tier_api_failed,event_type=#{event_type}," \
                  "version=#{result.version},crn=#{crn}"
    end
  end
end
