# On reception at an open prison, there are special rules for the
# responsibility determination for an offender.  These rules are built
# into the responsibility calculation but also an email
# should be sent to the offender's LDU (if the LDU's email address
# can be determined.)

class OpenPrisonTransferJob < ApplicationJob
  queue_as :default

  def perform(movement_json)
    # movement_json is already in snake case format so we just need to call Movement.new
    movement = Nomis::Movement.new(JSON.parse(movement_json))

    offender = OffenderService.get_offender(movement.offender_no)
    return if offender.nil? || !offender.nps_case?

    # Re-check that they're in an open prison
    return unless PrisonService.open_prison?(offender.prison_id)

    Rails.logger.info("[MOVEMENT] Processing move to open prison for #{offender.offender_no}")
    send_email(offender, movement) if ldu_email_address(offender).present?
  end

private

  def send_email(offender, movement)
    alloc = last_allocation(offender)

    PomMailer.responsibility_override_open_prison(
      prisoner_name: offender.full_name,
      prisoner_number: offender.offender_no,
      responsible_pom_name: alloc.try(:primary_pom_name) || 'N/A',
      responsible_pom_email: last_pom_email(alloc) || 'N/A',
      prison_name: PrisonService.name_for(movement.to_agency),
      previous_prison_name: PrisonService.name_for(movement.from_agency),
      email: ldu_email_address(offender)
    ).deliver_later
  end

  def last_allocation(offender)
    # Find the last allocation for an offender where they had a primary
    # pom. May return nil.
    alloc = Allocation.find_by(nomis_offender_id: offender.offender_no)
    return nil if alloc.blank?

    AllocationService.get_versions_for(alloc).reverse.detect { |allocation|
      allocation.primary_pom_nomis_id.present?
    }
  end

  def last_pom_email(allocation)
    return nil if allocation.blank?

    StaffMember.new(allocation.primary_pom_nomis_id).email_address
  end

  def ldu_email_address(offender)
    offender.ldu.try(:email_address)
  end
end
