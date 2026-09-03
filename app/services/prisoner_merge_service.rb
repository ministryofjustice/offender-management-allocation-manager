# frozen_string_literal: true

class PrisonerMergeService
  # One record per prisoner. We move the record only when the canonical ID
  # does not already have one
  REASSIGNABLE_MODELS = [
    CaseInformation,
    AllocationHistory,
    Responsibility,
    HandoverProgressChecklist,
    CalculatedHandoverDate,
  ].freeze

  # Many records per prisoner. We move all of them to the canonical ID
  # These tables have no unique constraint on `nomis_offender_id` alone,
  # so bulk update is safe
  BULK_REASSIGNABLE_MODELS = [
    EarlyAllocation,
    VictimLiaisonOfficer,
  ].freeze

  attr_reader :old_offender_id, :new_offender_id, :logger

  def initialize(old_offender_id:, new_offender_id:, logger: Rails.logger)
    @old_offender_id = old_offender_id
    @new_offender_id = new_offender_id
    @logger = logger
  end

  def process
    ApplicationRecord.transaction do
      canonical_id = record_merge

      # TODO: keep it feature-flagged for a while to make it easier to disable it if needed
      return unless FeatureFlags.prisoner_merges.enabled?

      Auditable.without_audit_events do
        migrate_records(canonical_id)
      end
    end
  end

  def self.locally_tracked?(nomis_offender_id)
    Offender.exists?(nomis_offender_id:) ||
      (REASSIGNABLE_MODELS + BULK_REASSIGNABLE_MODELS).any? { it.exists?(nomis_offender_id:) } ||
      ParoleReview.exists?(nomis_offender_id:)
  end

private

  def record_merge
    merge_record = NomisIdMerge.create_with(new_nomis_id: new_offender_id)
                               .find_or_create_by!(old_nomis_id: old_offender_id)
    canonical_id = NomisIdMerge.canonical_id_for(merge_record.new_nomis_id)

    log_event(event_name: 'record_merge', extra: "canonical_id=#{canonical_id}")

    canonical_id
  end

  def migrate_records(canonical_id)
    return if old_offender_id == canonical_id

    # Ensure the canonical Offender row exists before re-pointing
    Offender.find_or_create_by!(nomis_offender_id: canonical_id)

    REASSIGNABLE_MODELS.each do |model_class|
      migrate_record(model_class:, canonical_id:)
    end

    BULK_REASSIGNABLE_MODELS.each do |model_class|
      migrate_bulk_records(model_class:, canonical_id:)
    end

    migrate_parole_reviews(canonical_id:)
  end

  # Reassigns same-schema record type keyed by nomis_offender_id. We only
  # move the record when the canonical ID does not already have one
  def migrate_record(model_class:, canonical_id:)
    old_record = model_class.find_by(nomis_offender_id: old_offender_id)
    return unless old_record

    record_type = model_class.model_name.singular
    extra_log = "record=#{record_type},canonical_id=#{canonical_id}"

    if model_class.exists?(nomis_offender_id: canonical_id)
      log_event(event_name: 'migrate_record_already_present', extra: extra_log)
      return
    end

    old_record.nomis_offender_id = canonical_id
    old_record.save!(validate: false)

    publish_merge_audit_event(record_type:, canonical_id:)

    log_event(event_name: 'migrate_record', extra: extra_log)
  end

  # Reassigns all records for old_offender_id to canonical_id in a single
  # UPDATE. Used for tables that hold multiple rows per prisoner
  def migrate_bulk_records(model_class:, canonical_id:)
    record_type = model_class.model_name.singular
    records = model_class.where(nomis_offender_id: old_offender_id).to_a
    count = records.count
    return if count.zero?

    records.each do |record|
      record.nomis_offender_id = canonical_id
      record.save!(validate: false)
    end

    publish_merge_audit_event(record_type:, canonical_id:)

    log_event(
      event_name: 'migrate_bulk_records',
      extra: "record=#{record_type},count=#{count},canonical_id=#{canonical_id}"
    )
  end

  # `ParoleReview` is intentionally handled as a one-off because it has a
  # composite unique index on (review_id, nomis_offender_id)
  def migrate_parole_reviews(canonical_id:)
    old_parole_reviews = ParoleReview.where(nomis_offender_id: old_offender_id)
    return unless old_parole_reviews.exists?

    canonical_review_ids = ParoleReview.where(nomis_offender_id: canonical_id).pluck(:review_id)

    deleted  = old_parole_reviews.where(review_id: canonical_review_ids).delete_all
    migrated = ParoleReview.where(nomis_offender_id: old_offender_id).update_all(nomis_offender_id: canonical_id)
    return if deleted.zero? && migrated.zero?

    publish_merge_audit_event(record_type: 'parole_review', canonical_id:)

    log_event(
      event_name: 'migrate_parole_reviews',
      extra: "record=parole_review,migrated=#{migrated},deleted=#{deleted},canonical_id=#{canonical_id}"
    )
  end

  def publish_merge_audit_event(record_type:, canonical_id:)
    AuditEvent.publish(
      nomis_offender_id: canonical_id,
      tags: %w[service prisoner_merge migrated] + [record_type],
      system_event: true,
      data: {
        'old_offender_id' => old_offender_id,
        'new_offender_id' => new_offender_id,
        'canonical_id' => canonical_id,
      }.compact
    )
  end

  def log_context
    "service=prisoner_merge_service,old_offender_id=#{old_offender_id},new_offender_id=#{new_offender_id}"
  end

  def log_event(event_name:, extra: nil, message: nil)
    payload = "event=#{event_name},#{log_context}"
    payload += ",#{extra}" if extra
    payload += "|#{message}" if message
    logger.info(payload)
  end
end
