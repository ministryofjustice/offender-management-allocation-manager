# On reception at an open prison, there are special rules for the
# responsibility determination for an offender.  These rules are built
# into the responsibility calculation but also an email
# should be sent to the offender's LDU (if the LDU's email address
# can be determined.)

class OpenPrisonTransferJob < ApplicationJob
  queue_as :default

  def perform(movement_json)
    # movement_json is already in snake case format so we just need to call Movement.new
    movement = HmppsApi::Movement.new(JSON.parse(movement_json))

    offender = OffenderService.get_offender(movement.offender_no)

    return unless offender.present? && offender.nps_case? && offender.ldu_email_address.present? &&
      PrisonService.open_prison?(offender.prison_id)

    Rails.logger.info("[MOVEMENT] Processing move to open prison for #{offender.offender_no}")

    if offender.com_responsible?
      # Assumption: COM is responsible, so we are following pre-policy rules
      #   (i.e. OMIC rules don't apply in this open prison yet)
      # Action: Email the LDU asking for a Responsible COM to be allocated because OMIC rules don't apply.
      send_email_prepolicy(offender, movement)

    elsif offender.com_supporting?
      # Assumption: OMIC rules apply in this prison and the offender's sentence is indeterminate,
      # therefore a COM is needed from the moment they move into the prison.
      # Action: Email the LDU asking for a Supporting COM to be allocated, as per OMIC rules.
      send_email_supporting_com_needed(offender, movement)
    end
    # Else assumption: OMIC rules apply in this prison, but the offender doesn't need a COM yet.
    # This will apply to determinate offenders, because they don't need a COM immediately.
    # Action: do nothing – the LDU will be notified by the upcoming handover emails when a COM is needed.
  end

private

  def send_email_prepolicy(offender, movement)
    alloc = last_allocation(offender)

    CommunityMailer.open_prison_prepolicy_responsible_com_needed(
      prisoner_name: offender.full_name,
      prisoner_number: offender.offender_no,
      prisoner_crn: offender.crn,
      previous_pom_name: alloc.try(:primary_pom_name) || 'N/A',
      previous_pom_email: last_pom_email(alloc) || 'N/A',
      prison_name: PrisonService.name_for(movement.to_agency),
      previous_prison_name: PrisonService.name_for(movement.from_agency),
      email: offender.ldu_email_address
    ).deliver_later
  end

  def send_email_supporting_com_needed(offender, movement)
    CommunityMailer.open_prison_supporting_com_needed(
      prisoner_name: offender.full_name,
      prisoner_number: offender.offender_no,
      prisoner_crn: offender.crn,
      prison_name: PrisonService.name_for(movement.to_agency),
      ldu_email: offender.ldu_email_address
    ).deliver_later

    EmailHistory.create! nomis_offender_id: offender.offender_no, name: offender.ldu_name,
                         email: offender.ldu_email_address,
                         event: EmailHistory::OPEN_PRISON_COMMUNITY_ALLOCATION,
                         prison: offender.prison_id
  end

  def last_allocation(offender)
    # Find the last allocation for an offender where they had a primary
    # pom. May return nil.
    alloc = Allocation.find_by(nomis_offender_id: offender.offender_no)
    return nil if alloc.blank?

    alloc.get_old_versions.reverse.detect { |allocation|
      allocation.primary_pom_nomis_id.present?
    }
  end

  def last_pom_email(allocation)
    return nil if allocation.blank?

    HmppsApi::PrisonApi::PrisonOffenderManagerApi.fetch_email_addresses(allocation.primary_pom_nomis_id).first
  end
end
