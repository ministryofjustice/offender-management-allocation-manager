# frozen_string_literal: true

class RecalculateHandoverDateJob < ApplicationJob
  queue_as :default

  def perform(nomis_offender_id)
    offender = OffenderService.get_offender(nomis_offender_id)
    if offender&.inside_omic_policy?
      # Recalculate handover dates, which will trigger a push to the Community API after_save
      recalculate_dates_for(offender)
    end
  end

private

  def recalculate_dates_for(offender)
    # we have to go direct to handover data to avoid being blocked when COM is responsible
    handover = HandoverDateService.handover(offender)
    case_info = CaseInformation.find_by!(nomis_offender_id: offender.offender_no)
    record = case_info.calculated_handover_date.presence || case_info.build_calculated_handover_date
    record.assign_attributes(
      responsibility: handover.responsibility,
      start_date: handover.start_date,
      handover_date: handover.handover_date,
      reason: handover.reason
    )
    if handover.community_responsible? &&
      handover.reason.to_sym == :less_than_10_months_left_to_serve &&
      case_info.ldu.present? &&
      case_info.com_name.nil?
      # need to chase if we haven't chased recently
      last_chaser = case_info.email_histories.where(event: EmailHistory::IMMEDIATE_COMMUNITY_ALLOCATION).last
      if last_chaser.nil? || last_chaser.created_at < 2.days.ago
        CommunityMailer.assign_com_less_than_10_months(
          email: case_info.ldu.email_address,
          crn_number: case_info.crn,
          prison_name: PrisonService.name_for(offender.prison_id),
          prisoner_name: "#{offender.first_name} #{offender.last_name}",
          prisoner_number: offender.offender_no
        ).deliver_later
        case_info.email_histories.create! prison: offender.prison_id,
                                          name: case_info.ldu.name,
                                          email: case_info.ldu.email_address,
                                          event: EmailHistory::IMMEDIATE_COMMUNITY_ALLOCATION
      end
    end

    record.save! if record.changed?

    # Don't push if the CaseInformation record is a manual entry (meaning it didn't match against nDelius)
    # This avoids 404 Not Found errors for offenders who don't exist in nDelius (they could be Scottish, etc.)
    push_to_delius record unless case_info.manual_entry?

    request_supporting_com record, case_info, offender
  end

  def push_to_delius record
    # Don't push if the dates haven't changed
    if record.saved_change_to_start_date? || record.saved_change_to_handover_date?
      PushHandoverDatesToDeliusJob.perform_later record
    end
  end

  def request_supporting_com record, case_info, offender
    reason_change = %w[nps_indeterminate nps_indeterminate_open]
    responsibility_change = [CalculatedHandoverDate::CUSTODY_ONLY, CalculatedHandoverDate::CUSTODY_WITH_COM]

    if record.saved_change_to_reason == reason_change &&
      record.saved_change_to_responsibility == responsibility_change &&
      offender.ldu_email_address.present? &&
      offender.allocated_com_name.blank?

      # Offender has moved to Open Prison conditions and now needs a supporting COM
      # Note: this covers both Male and Female offenders
      CommunityMailer.open_prison_supporting_com_needed(
        prisoner_name: offender.full_name,
        prisoner_number: offender.offender_no,
        prisoner_crn: offender.crn,
        prison_name: PrisonService.name_for(offender.prison_id),
        ldu_email: offender.ldu_email_address
      ).deliver_later

      case_info.email_histories.create! name: offender.ldu_name,
                           email: offender.ldu_email_address,
                           event: EmailHistory::OPEN_PRISON_COMMUNITY_ALLOCATION,
                           prison: offender.prison_id
    end
  end
end
