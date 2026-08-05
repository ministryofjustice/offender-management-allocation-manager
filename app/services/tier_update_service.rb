class TierUpdateService
  Result = Struct.new(:status, :errors, :old_tier, :new_tier, :version, keyword_init: true)

  def self.call(crn:, audit_tags:)
    version = FeatureFlags.new_tiers.enabled? ? 3 : 2

    case_information = CaseInformation.find_by(crn:)
    return Result.new(status: :unchanged, version:) if case_information.nil?

    tier_info = HmppsApi::TieringApi.get_tier(crn, version:)
    return Result.new(status: :tier_api_failed, version:) if tier_info.nil? || tier_info[:tier].blank?

    new_tier = tier_info[:tier][0]
    old_tier = case_information.tier
    return Result.new(status: :unchanged, old_tier:, new_tier:, version:) if new_tier == old_tier

    case_information.tier = new_tier
    case_information.manual_entry = false
    attrs_before = case_information.changed_attributes

    if case_information.save
      publish_audit_event(
        case_information:, audit_tags:, attrs_before:
      )
      Result.new(status: :updated, old_tier:, new_tier:, version:)
    else
      errors = case_information.errors.full_messages.join(', ')
      Result.new(status: :update_failed, errors:, old_tier:, new_tier:, version:)
    end
  end

  def self.publish_audit_event(case_information:, audit_tags:, attrs_before:)
    AuditEvent.publish(
      nomis_offender_id: case_information.nomis_offender_id,
      tags: audit_tags + %w[case_information tier changed],
      system_event: true,
      data: {
        'before' => attrs_before,
        'after' => case_information.slice(attrs_before.keys)
      }
    )
  end
  private_class_method :publish_audit_event
end
