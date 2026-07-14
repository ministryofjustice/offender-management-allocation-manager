# frozen_string_literal: true

class RecalculateHandoverDateJob < ApplicationJob
  queue_as :default

  def perform(nomis_offender_id)
    @nomis_offender = OffenderService.get_offender(nomis_offender_id)
    return unless nomis_offender&.inside_omic_policy?

    recalculate_dates_for_offender
  end

private

  attr_reader :nomis_offender, :db_offender, :record, :com_email_eligible

  def recalculate_dates_for_offender
    save_handover_calculation

    # Side effects that depend on the committed state but should not
    # prevent the core recalculation from persisting. Each runs independently
    # so a failure in one does not block the others.
    safely { publish_event }
    safely { maybe_reset_handover_checklist }
    safely { maybe_stamp_handover_episode }
    safely { request_supporting_com }
    safely { assign_com_email }
  end

  # The only DB-mutating part: saves the recalculated handover date and audit event atomically.
  def save_handover_calculation
    ApplicationRecord.transaction do
      handover = HandoverDateService.handover(nomis_offender)
      @db_offender = Offender.find_by! nomis_offender_id: nomis_offender.offender_no
      @record = db_offender.calculated_handover_date.presence || db_offender.build_calculated_handover_date
      handover_before = record.attributes.except('id', 'created_at', 'updated_at')
      record.assign_attributes(
        responsibility: handover.responsibility,
        start_date: handover.start_date,
        handover_date: handover.handover_date,
        reason: handover.reason,
      )

      if record.changed?
        record.offender_attributes_to_archive = nomis_offender.attributes_to_archive
        record.last_calculated_at = Time.zone.now.utc
        record.save!
        handover_after = record.attributes.except('id', 'created_at', 'updated_at')

        AuditEvent.publish(
          nomis_offender_id: handover_after['nomis_offender_id'],
          tags: %w[job recalculate_handover_date handover changed],
          system_event: true,
          data: {
            'before' => handover_before,
            'after' => handover_after,
            'nomis_offender_state' => nomis_offender.attributes_to_archive,
          }
        )
      end

      @com_email_eligible = handover.community_responsible? &&
                            handover.reason.to_sym == :determinate_short &&
                            nomis_offender.ldu_email_address.present? &&
                            nomis_offender.allocated_com_name.blank?
    end
  end

  def publish_event
    return unless record.saved_change_to_start_date? || record.saved_change_to_handover_date?

    event = DomainEvents::EventFactory.build_handover_event(
      host: Rails.configuration.allocation_manager_host,
      noms_number: record.nomis_offender_id
    )
    event.publish(job: 'recalculate_handover_date')
  end

  # Reset all checklist tasks when the handover episode has ended, meaning either:
  # - responsibility reverted to custody-only (e.g. sentence recalculation), or
  # - a date change moved the case off all handover lists while already custody-only.
  # Does not trigger on date adjustments that keep the case on a handover list,
  # and does not trigger when responsibility moves forward (e.g. upcoming -> in-progress).
  def maybe_reset_handover_checklist
    responsibility_reverted = record.saved_change_to_responsibility? && record.responsibility == CalculatedHandoverDate::CUSTODY_ONLY
    dates_moved_off_lists = record.saved_change_to_handover_date? &&
                            record.responsibility == CalculatedHandoverDate::CUSTODY_ONLY &&
                            !CalculatedHandoverDate.in_handover_window?(record.nomis_offender_id)

    return unless responsibility_reverted || dates_moved_off_lists

    checklist = HandoverProgressChecklist.find_by(nomis_offender_id: record.nomis_offender_id)
    return unless checklist

    # Blank whodunnit so both PaperTrail and Auditable record this as system-initiated,
    # even when the job runs synchronously within a user request (e.g. parole review).
    PaperTrail.request(whodunnit: nil) do
      checklist.update!(
        reviewed_oasys: false,
        contacted_com: false,
        attended_handover_meeting: false,
        sent_handover_report: false,
        handover_episode_started_at: nil,
      )
    end
  end

  # Stamp the handover episode start date when responsibility shifts away from
  # custody-only (i.e. the handover has formally begun). This date is frozen for
  # the duration of the episode and used to determine which task version applies.
  def maybe_stamp_handover_episode
    return if record.responsibility == CalculatedHandoverDate::CUSTODY_ONLY
    return if record.handover_date.nil?

    # Blank whodunnit so both PaperTrail and Auditable record this as system-initiated,
    # even when the job runs synchronously within a user request (e.g. parole review).
    PaperTrail.request(whodunnit: nil) do
      checklist = HandoverProgressChecklist.find_by(nomis_offender_id: record.nomis_offender_id)

      if checklist
        checklist.update!(handover_episode_started_at: Date.current) if checklist.handover_episode_started_at.nil?
      else
        HandoverProgressChecklist.create!(
          nomis_offender_id: record.nomis_offender_id,
          handover_episode_started_at: Date.current,
        )
      end
    end
  end

  def request_supporting_com
    reason_change = %w[indeterminate indeterminate_open]
    responsibility_change = [CalculatedHandoverDate::CUSTODY_ONLY, CalculatedHandoverDate::CUSTODY_WITH_COM]

    return unless record.saved_change_to_reason == reason_change &&
      record.saved_change_to_responsibility == responsibility_change &&
      nomis_offender.ldu_email_address.present? &&
      nomis_offender.allocated_com_name.blank?

    CommunityMailer.with(
      prisoner_name: nomis_offender.full_name,
      prisoner_number: nomis_offender.offender_no,
      prisoner_crn: nomis_offender.crn,
      prison_name: PrisonService.name_for(nomis_offender.prison_id),
      ldu_email: nomis_offender.ldu_email_address,
      email_history_name: nomis_offender.ldu_name
    ).open_prison_supporting_com_needed.deliver_later
  end

  # TODO: This should probably be a scheduled job — we are effectively using this like a cron every 2 days
  def assign_com_email
    return unless com_email_eligible

    case_info = db_offender.case_information

    # There is frequently bad data on staging/dev, thus this check
    return if case_info.nil? || case_info.crn.blank?

    last_com_email = db_offender.email_histories.immediate_community_allocation.last

    # send email for the first time, or resend it if we haven't recently
    if last_com_email.nil? || last_com_email.created_at < 2.days.ago
      CommunityMailer.with(
        email: case_info.ldu_email_address,
        email_history_name: case_info.ldu_name,
        prison_name: PrisonService.name_for(nomis_offender.prison_id),
        prisoner_name: "#{nomis_offender.first_name} #{nomis_offender.last_name}",
        prisoner_number: nomis_offender.offender_no,
        crn_number: case_info.crn,
      ).assign_com_less_than_10_months.deliver_later
    end
  end

  def safely
    yield
  rescue StandardError => e
    Rails.logger.error(
      'event=recalculate_handover_side_effect_failed,' \
      "nomis_offender_id=#{nomis_offender.offender_no}," \
      "error=#{e.class}|#{e.message}"
    )
  end
end
