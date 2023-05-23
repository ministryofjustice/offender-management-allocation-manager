# frozen_string_literal: true

class RecalculateHandoverDateJob < ApplicationJob
  queue_as :default

  def perform(nomis_offender_id)
    offender = OffenderService.get_offender(nomis_offender_id)
    if offender&.inside_omic_policy?
      recalculate_dates_for(offender)
    end
  end

private

  def recalculate_dates_for(nomis_offender)
    # we have to go direct to handover data to avoid being blocked when COM is responsible
    handover = HandoverDateService.handover(nomis_offender)
    db_offender = Offender.find_by! nomis_offender_id: nomis_offender.offender_no
    case_info = db_offender.case_information
    record = db_offender.calculated_handover_date.presence || db_offender.build_calculated_handover_date
    record.assign_attributes(
      responsibility: handover.responsibility,
      start_date: handover.start_date,
      handover_date: handover.handover_date,
      reason: handover.reason,
      offender_attributes_to_archive: nomis_offender.attributes_to_archive,
    )
    if handover.community_responsible? &&
      handover.reason.to_sym == :less_than_10_months_left_to_serve &&
      nomis_offender.ldu_email_address.present? &&
      nomis_offender.allocated_com_name.blank?
      # need to chase if we haven't chased recently
      last_chaser = db_offender.email_histories.where(event: EmailHistory::IMMEDIATE_COMMUNITY_ALLOCATION).last
      if last_chaser.nil? || last_chaser.created_at < 2.days.ago
        # create the history first so that the validations will help with hard failures due to coding errors
        # rather than waiting for the mailer to object
        db_offender.email_histories.create! prison: nomis_offender.prison_id,
                                            name: case_info.ldu_name,
                                            email: case_info.ldu_email_address,
                                            event: EmailHistory::IMMEDIATE_COMMUNITY_ALLOCATION
        # This is queued so that soft failures don't kill the whole job
        CommunityMailer.assign_com_less_than_10_months(
          email: case_info.ldu_email_address,
          crn_number: case_info.crn,
          prison_name: PrisonService.name_for(nomis_offender.prison_id),
          prisoner_name: "#{nomis_offender.first_name} #{nomis_offender.last_name}",
          prisoner_number: nomis_offender.offender_no
        ).deliver_later
      end
    end

    record.save! if record.changed?

    # Don't push if the CaseInformation record is a manual entry (meaning it didn't match against nDelius)
    # This avoids 404 Not Found errors for offenders who don't exist in nDelius (they could be Scottish, etc.)
    push_to_delius record unless case_info.manual_entry?

    request_supporting_com record, db_offender, nomis_offender
  end

  def push_to_delius(record)
    # Don't push if the dates haven't changed
    if record.saved_change_to_start_date? || record.saved_change_to_handover_date?
      if USE_EVENTS_TO_PUSH_HANDOVER_TO_DELIUS
        event = DomainEvents::EventFactory.build_handover_event(host: Rails.configuration.allocation_manager_host,
                                                                noms_number: record.nomis_offender_id)
        event.publish(job: 'recalculate_handover_date_job')
      else
        PushHandoverDatesToDeliusJob.perform_later record
      end
    end
  end

  def request_supporting_com(record, offender, nomis_offender)
    reason_change = %w[indeterminate indeterminate_open]
    responsibility_change = [CalculatedHandoverDate::CUSTODY_ONLY, CalculatedHandoverDate::CUSTODY_WITH_COM]

    if record.saved_change_to_reason == reason_change &&
      record.saved_change_to_responsibility == responsibility_change &&
      nomis_offender.ldu_email_address.present? &&
      nomis_offender.allocated_com_name.blank?

      # Offender has moved to Open Prison conditions and now needs a supporting COM
      # Note: this covers both Male and Female offenders
      offender.email_histories.create! name: nomis_offender.ldu_name,
                                       email: nomis_offender.ldu_email_address,
                                       event: EmailHistory::OPEN_PRISON_COMMUNITY_ALLOCATION,
                                       prison: nomis_offender.prison_id
      CommunityMailer.open_prison_supporting_com_needed(
        prisoner_name: nomis_offender.full_name,
        prisoner_number: nomis_offender.offender_no,
        prisoner_crn: nomis_offender.crn,
        prison_name: PrisonService.name_for(nomis_offender.prison_id),
        ldu_email: nomis_offender.ldu_email_address
      ).deliver_later
    end
  end
end
