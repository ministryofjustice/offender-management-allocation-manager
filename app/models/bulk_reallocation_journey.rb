# frozen_string_literal: true

# Wraps the session-backed state for a bulk reallocation journey.
# This is a plain, not persisted, Ruby object that reads and mutates
# a hash stored in the Rails session.
#
class BulkReallocationJourney
  attr_reader :data

  delegate :to_h, to: :data

  def initialize(session_data)
    @data = (session_data || {}).with_indifferent_access
  end

  # ── identity ────────────────────────────────────────────────────────

  def source_pom_id = data[:source_pom_id].to_i
  def target_pom_id = data[:target_pom_id].to_i

  def matches?(source_staff_id, target_staff_id)
    data.present? &&
      source_pom_id == source_staff_id.to_i &&
      target_pom_id == target_staff_id.to_i
  end

  # ── offender ID sets ────────────────────────────────────────────────

  def selected_offender_ids  = Array(data[:selected_offender_ids])
  def override_offender_ids  = Array(data[:override_offender_ids])

  def pending_override_offender_ids
    override_offender_ids.reject { overrides.key?(it) }
  end

  def missing_selected_offender_ids(active_offender_ids)
    selected_offender_ids - Array(active_offender_ids)
  end

  def stale?(active_offender_ids)
    missing_selected_offender_ids(active_offender_ids).any?
  end

  # ── overrides ───────────────────────────────────────────────────────

  def overrides
    (data[:overrides] || {}).with_indifferent_access
  end

  def override_for(nomis_offender_id)
    overrides[nomis_offender_id] || {}
  end

  def store_override_attributes!(nomis_offender_id, override_attributes)
    @data = data.merge(overrides: overrides.merge(nomis_offender_id => override_attributes))
  end

  # ── mutations ───────────────────────────────────────────────────────

  def exclude_offender!(nomis_offender_id)
    @data = data.merge(
      selected_offender_ids: selected_offender_ids - [nomis_offender_id],
      override_offender_ids: override_offender_ids - [nomis_offender_id],
      overrides: overrides.except(nomis_offender_id),
    )
  end
end
