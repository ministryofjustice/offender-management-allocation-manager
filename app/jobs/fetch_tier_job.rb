# frozen_string_literal: true

# Fetches the authoritative tier from the Tier API for a CaseInformation
# record. Used on first nDelius import (where the probation-record tier
# may be stale) and can also be enqueued in bulk to refresh all cases.
class FetchTierJob < ApplicationJob
  queue_as :default

  # 5 retries (~10 min with exp backoff) is sufficient for transient issues
  sidekiq_options retry: 5

  def perform(crn, trigger_method: :manual)
    prefix = "crn=#{crn},trigger_method=#{trigger_method},version=#{tier_api_version},job=fetch_tier_job"

    case_info = CaseInformation.find_by(crn:)
    if case_info.nil?
      logger.warn("#{prefix},event=case_info_not_found")
      return
    end

    tier_info = HmppsApi::TieringApi.get_tier(crn, version: tier_api_version)
    if tier_info.nil? || tier_info[:tier].blank?
      logger.warn("#{prefix},event=tier_api_failed")
      return
    end

    new_tier = tier_info[:tier][0]
    old_tier = case_info.tier

    return if new_tier == old_tier

    case_info.tier = new_tier

    attrs_before = case_info.changed_attributes

    if case_info.save
      AuditEvent.publish(
        nomis_offender_id: case_info.nomis_offender_id,
        tags: ['job', 'fetch_tier_job', 'case_information', 'tier', 'changed', trigger_method.to_s],
        system_event: true,
        data: {
          'before' => attrs_before,
          'after' => case_info.slice(attrs_before.keys)
        }
      )

      logger.info("#{prefix},event=tier_updated,old_tier=#{old_tier},new_tier=#{new_tier}")
    else
      logger.error("#{prefix},event=tier_update_failed,old_tier=#{old_tier},new_tier=#{new_tier}|#{case_info.errors.full_messages.join(',')}")
    end
  end

private

  def tier_api_version
    FeatureFlags.new_tiers.enabled? ? 3 : 2
  end
end
