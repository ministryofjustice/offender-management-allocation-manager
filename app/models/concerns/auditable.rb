# frozen_string_literal: true

module Auditable
  extend ActiveSupport::Concern

  AUDIT_EXCLUDED_KEYS = %w[id nomis_offender_id].freeze

  class << self
    def without_audit_events
      previous = ActiveSupport::IsolatedExecutionState[:auditable_events_suppressed]
      ActiveSupport::IsolatedExecutionState[:auditable_events_suppressed] = true
      yield
    ensure
      ActiveSupport::IsolatedExecutionState[:auditable_events_suppressed] = previous
    end

    def audit_events_suppressed?
      ActiveSupport::IsolatedExecutionState[:auditable_events_suppressed] == true
    end
  end

private

  def save_audit_event
    return if Auditable.audit_events_suppressed?

    excluded = AUDIT_EXCLUDED_KEYS + audit_excluded_keys

    if destroyed?
      before_changes = attributes.except(*excluded)
      after_changes  = {}
    else
      return unless previous_changes.any?

      before_changes = previous_changes.transform_values(&:first)
      after_changes  = previous_changes.transform_values(&:last)

      [before_changes, after_changes].each do |changes_hash|
        excluded.each { changes_hash.delete(it) }
      end
    end

    AuditEvent.publish(
      nomis_offender_id: (nomis_offender_id if respond_to?(:nomis_offender_id)),
      tags: [*audit_event_tags, audit_action_tag],
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

  def audit_action_tag
    return 'destroyed' if destroyed?
    return 'created'   if previous_changes.key?('id')

    'changed'
  end
end
