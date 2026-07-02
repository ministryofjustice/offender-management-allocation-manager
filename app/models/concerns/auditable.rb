# frozen_string_literal: true

module Auditable
  extend ActiveSupport::Concern

private

  def save_audit_event
    return unless previous_changes.any?

    before_changes = previous_changes.transform_values(&:first)
    after_changes  = previous_changes.transform_values(&:last)

    [before_changes, after_changes].each do |changes_hash|
      audit_excluded_keys.each { changes_hash.delete(it) }
    end

    AuditEvent.publish(
      nomis_offender_id: (nomis_offender_id if has_attribute?(:nomis_offender_id)),
      tags: audit_event_tags,
      system_event: PaperTrail.request.whodunnit.blank?,
      username: PaperTrail.request.whodunnit,
      data: audit_additional_data.merge(
        'before' => before_changes,
        'after' => after_changes
      )
    )
  end

  # Override in including models to exclude specific keys from the audit diff
  def audit_excluded_keys
    []
  end

  # Override in including models to merge additional identifying data
  def audit_additional_data
    {}
  end
end
