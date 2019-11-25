# frozen_string_literal: true

class MovementService
  def self.movements_on(date, direction_filters: [], type_filters: [])
    movements = Nomis::Elite2::MovementApi.movements_on_date(date)

    if direction_filters.any?
      movements = movements.select { |m|
        direction_filters.include?(m.direction_code)
      }
    end

    if type_filters.any?
      movements = movements.select { |m|
        type_filters.include?(m.movement_type)
      }
    end

    movements
  end

  def self.process_movement(movement)
    if movement.movement_type == Nomis::MovementType::RELEASE
      return process_release(movement)
    end

    # We need to check whether the from_agency is from within the prison estate
    # to know whether it is a transfer.  If it isn't then we want to bail and
    # not process the new admission.
    if [Nomis::MovementType::ADMISSION,
        Nomis::MovementType::TRANSFER].include?(movement.movement_type)

      return process_transfer(movement)
    end

    Rails.logger.info("[MOVEMENT] Ignoring #{movement.movement_type}")

    false
  end

private

  def self.process_transfer(transfer)
    return false unless transfer.direction_code == 'IN'

    Rails.logger.info("[MOVEMENT] Processing transfer for #{transfer.offender_no}")

    if PrisonService.open_prison?(transfer.to_agency)
      # There are special rules for responsibility when offenders
      # move to open prisons so we will trigger this job to send
      # an email to the LDU
      OpenPrisonTransferJob.perform_later(transfer.to_json)
    end

    # Bail if this is a new admission to prison
    return false unless transfer.from_prison? && transfer.to_prison?

    # We only want to deallocate the offender if they have not already been
    # allocated at their new prison
    if Allocation.where(
      nomis_offender_id: transfer.offender_no,
      prison: transfer.to_agency
    ).count > 0

      Rails.logger.info("[MOVEMENT] Offender #{transfer.offender_no} was transferred but \
        an allocation at #{transfer.to_agency} already exists")

      return false
    end

    Rails.logger.info("[MOVEMENT] De-allocating #{transfer.offender_no}")

    alloc = Allocation.find_by(nomis_offender_id: transfer.offender_no)

    # frozen_string_literal: true
    # We need to check whether the from_agency is from within the prison estate
    # to know whether it is a transfer.  If it isn't then we want to bail and
    # not process the new admission.
    # There are special rules for responsibility when offenders
    # move to open prisons so we will trigger this job to send
    # an email to the LDU
    # Bail if this is a new admission to prison
    # We only want to deallocate the offender if they have not already been
    # allocated at their new prison
    # When an offender is released, we can no longer rely on their
    # case information (in case they come back one day), and we
    # should de-activate any current allocations.
    alloc&.deallocate_offender(Allocation::OFFENDER_TRANSFERRED)
    true
  end

  # When an offender is released, we can no longer rely on their
  # case information (in case they come back one day), and we
  # should de-activate any current allocations.
  def self.process_release(release)
    return false unless release.to_agency == 'OUT' && release.from_prison?

    Rails.logger.info("[MOVEMENT] Processing release for #{release.offender_no}")

    CaseInformation.where(nomis_offender_id: release.offender_no).destroy_all
    alloc = Allocation.find_by(nomis_offender_id: release.offender_no)
    # frozen_string_literal: true
    # We need to check whether the from_agency is from within the prison estate
    # to know whether it is a transfer.  If it isn't then we want to bail and
    # not process the new admission.
    # There are special rules for responsibility when offenders
    # move to open prisons so we will trigger this job to send
    # an email to the LDU
    # Bail if this is a new admission to prison
    # We only want to deallocate the offender if they have not already been
    # allocated at their new prison
    # When an offender is released, we can no longer rely on their
    # case information (in case they come back one day), and we
    # should de-activate any current allocations.
    alloc&.deallocate_offender(Allocation::OFFENDER_RELEASED)

    true
  end
end
