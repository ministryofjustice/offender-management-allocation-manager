# frozen_string_literal: true

class MovementService
  ADMISSION_MOVEMENT_CODE = 'IN'
  RELEASE_MOVEMENT_CODE = 'OUT'

  def self.movements_on(date)
    HmppsApi::PrisonApi::MovementApi.movements_on_date(date)
  end

  def self.process_movement(movement)
    if movement.movement_type == HmppsApi::MovementType::RELEASE
      return process_release(movement)
    end

    # We need to check whether the from_agency is from within the prison estate
    # to know whether it is a transfer.  If it isn't then we want to bail and
    # not process the new admission.
    if [HmppsApi::MovementType::ADMISSION,
        HmppsApi::MovementType::TRANSFER].include?(movement.movement_type)

      return process_transfer(movement)
    end

    Rails.logger.info("[MOVEMENT] Ignoring #{movement.movement_type}")

    false
  end

private

  def self.process_transfer(transfer)
    return false unless transfer.in?
    return false if transfer.from_agency.blank?

    Rails.logger.info("[MOVEMENT] Processing transfer for #{transfer.offender_no}")

    # Remove the case information and deallocate offender
    # when the movement is from immigration or a detention centre
    # and is not going back to a prison OR
    # when the movement is from a prison to an immigration or detention centre
    if (transfer.from_immigration? && !transfer.to_prison?) ||
       (transfer.from_prison? && transfer.to_immigration?)
      release_offender(transfer.offender_no, transfer.from_agency)

      return true
    end

    unless hospital_agencies.include?(transfer.from_agency) ||
           (transfer.from_prison? && transfer.to_prison?)
      return false
    end

    # We only want to deallocate the offender if they have not already been
    # allocated at their new prison
    if AllocationHistory.where(
      nomis_offender_id: transfer.offender_no,
      prison: transfer.to_agency
    ).count > 0

      Rails.logger.info("[MOVEMENT] Offender #{transfer.offender_no} was transferred but \
        an allocation at #{transfer.to_agency} already exists")

      return false
    end

    Rails.logger.info("[MOVEMENT] De-allocating #{transfer.offender_no}")

    alloc = AllocationHistory.active.find_by(nomis_offender_id: transfer.offender_no)
    alloc.deallocate_offender_after_transfer if alloc
    true
  end

  # When an offender is released, we can no longer rely on their
  # case information (in case they come back one day), and we
  # should de-activate any current allocations.
  def self.process_release(release)
    return false unless release.to_agency == RELEASE_MOVEMENT_CODE
    return false unless release.from_prison? || release.from_immigration? ||
                        hospital_agencies.include?(release.from_agency)

    release_offender(release.offender_no, release.from_agency)
    true
  end

  def self.release_offender(offender_no, from_agency)
    Rails.logger.info("[MOVEMENT] Processing release for #{offender_no}")

    CaseInformation.where(nomis_offender_id: offender_no).destroy_all

    alloc = AllocationHistory.active.find_by(nomis_offender_id: offender_no)
    alloc.deallocate_offender_after_release if alloc

    HmppsApi::ComplexityApi.inactivate(offender_no) if PrisonService.womens_prison?(from_agency)
  end

private

  def self.hospital_agencies
    @hospital_agencies ||= HmppsApi::PrisonApi::AgenciesApi.agency_ids_by_type(
      HmppsApi::PrisonApi::AgenciesApi::HOSPITAL_AGENCY_TYPE
    )
  end
end
