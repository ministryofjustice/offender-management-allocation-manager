# frozen_string_literal: true

class ProbationMergeService
  attr_reader :old_crn, :new_crn, :logger

  def initialize(old_crn:, new_crn:, logger: Rails.logger)
    @old_crn = old_crn
    @new_crn = new_crn
    @logger = logger
  end

  def process
    ApplicationRecord.transaction do
      canonical_crn = record_merge

      # TODO: keep it feature-flagged for a while to make it easier to disable it if needed
      return unless FeatureFlags.probation_merges.enabled?

      Auditable.without_audit_events do
        migrate_case_information(canonical_crn)
      end
    end
  end

  def self.locally_tracked?(crn)
    CaseInformation.exists?(crn:)
  end

private

  def record_merge
    merge_record = ProbationCaseMerge.record_merge!(old_crn:, new_crn:)
    canonical_crn = ProbationCaseMerge.canonical_crn_for(merge_record.new_crn)

    log_event(event_name: 'record_merge', extra: "canonical_crn=#{canonical_crn}")

    canonical_crn
  end

  def migrate_case_information(canonical_crn)
    return if old_crn == canonical_crn

    old_record = CaseInformation.find_by(crn: old_crn)
    return unless old_record

    extra_log = "record=case_information,canonical_crn=#{canonical_crn}"

    if CaseInformation.exists?(crn: canonical_crn)
      log_event(event_name: 'migrate_record_already_present', extra: extra_log)
      return
    end

    old_record.crn = canonical_crn
    old_record.save!(validate: false)

    publish_merge_audit_event(canonical_crn:, nomis_offender_id: old_record.nomis_offender_id)

    log_event(event_name: 'migrate_record', extra: extra_log)
  end

  def publish_merge_audit_event(canonical_crn:, nomis_offender_id:)
    AuditEvent.publish(
      nomis_offender_id:,
      tags: %w[service probation_merge migrated case_information],
      system_event: true,
      data: {
        'old_crn' => old_crn,
        'new_crn' => new_crn,
        'canonical_crn' => canonical_crn,
      }.compact
    )
  end

  def log_context
    "service=probation_merge_service,old_crn=#{old_crn},new_crn=#{new_crn}"
  end

  def log_event(event_name:, extra: nil, message: nil)
    payload = "event=#{event_name},#{log_context}"
    payload += ",#{extra}" if extra
    payload += "|#{message}" if message
    logger.info(payload)
  end
end
