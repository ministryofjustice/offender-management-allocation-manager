# frozen_string_literal: true

class ProbationUnmergeService
  attr_reader :old_crn, :new_crn, :logger

  def initialize(old_crn:, new_crn:, logger: Rails.logger)
    @old_crn = old_crn
    @new_crn = new_crn
    @logger = logger
  end

  def process
    ApplicationRecord.transaction do
      unmerged = record_unmerge
      return unless unmerged

      # TODO: keep it feature-flagged for a while to make it easier to disable it if needed
      return unless FeatureFlags.probation_merges.enabled?

      Auditable.without_audit_events do
        restore_case_information
      end
    end
  end

  def self.locally_tracked?(old_crn:, new_crn:)
    ProbationCaseMerge.active.exists?(old_crn:, new_crn:)
  end

private

  def record_unmerge
    unmerged = ProbationCaseMerge.record_unmerge!(old_crn:, new_crn:)
    event_name = unmerged ? 'record_unmerge' : 'record_unmerge_noop'
    log_event(event_name:, extra: "old_crn=#{old_crn},new_crn=#{new_crn}")
    unmerged
  end

  def restore_case_information
    extra_log = "record=case_information,old_crn=#{old_crn},new_crn=#{new_crn}"

    old_record = CaseInformation.find_by(crn: old_crn)
    if old_record
      log_event(event_name: 'unmerge_case_information_already_present', extra: extra_log)
      return
    end

    new_record = CaseInformation.find_by(crn: new_crn)
    unless new_record
      log_event(event_name: 'unmerge_case_information_source_missing', extra: extra_log)
      return
    end

    new_record.crn = old_crn
    new_record.save!(validate: false)

    publish_unmerge_audit_event(nomis_offender_id: new_record.nomis_offender_id)

    log_event(event_name: 'unmerge_case_information_restored', extra: extra_log)
  end

  def publish_unmerge_audit_event(nomis_offender_id:)
    AuditEvent.publish(
      nomis_offender_id:,
      tags: %w[service probation_merge unmerged case_information],
      system_event: true,
      data: {
        'old_crn' => old_crn,
        'new_crn' => new_crn,
      }
    )
  end

  def log_context
    "service=probation_unmerge_service,old_crn=#{old_crn},new_crn=#{new_crn}"
  end

  def log_event(event_name:, extra: nil, message: nil)
    payload = "event=#{event_name},#{log_context}"
    payload += ",#{extra}" if extra
    payload += "|#{message}" if message
    logger.info(payload)
  end
end
