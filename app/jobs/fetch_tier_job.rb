# frozen_string_literal: true

# Fetches the authoritative tier from the Tier API for a CaseInformation
# record. Used on first nDelius import where the probation-record tier may be
# stale. For bulk refresh of all cases use BulkFetchTierJob instead.
class FetchTierJob < ApplicationJob
  queue_as :default

  # Transient errors bubble up from `TieringApi` and are retried by Sidekiq
  # 5 retries (~10 min with exp backoff) is sufficient for transient issues
  sidekiq_options retry: 5

  def perform(crn, trigger_method: :manual)
    result = TierUpdateService.call(
      crn:, audit_tags: ['job', trigger_method.to_s]
    )

    prefix = "job=fetch_tier_job,trigger_method=#{trigger_method},crn=#{crn},version=#{result.version}"

    case result.status
    when :updated
      logger.info "#{prefix},event=tier_updated,old_tier=#{result.old_tier},new_tier=#{result.new_tier}"
    when :invalid_tier
      logger.error "#{prefix},event=tier_invalid,old_tier=#{result.old_tier},new_tier=#{result.new_tier}|#{result.errors}"
    when :update_failed
      logger.error "#{prefix},event=tier_update_failed,old_tier=#{result.old_tier},new_tier=#{result.new_tier}|#{result.errors}"
    when :tier_api_failed
      logger.warn "#{prefix},event=tier_api_failed"
    end
  end
end
