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

    false
  end

private

  def self.process_transfer(transfer)
    # Bail if this is a new admission to prison
    return false unless transfer.from_prison? && transfer.to_prison?
    return false unless transfer.direction_code == 'IN'

    # We only want to deallocate the offender if they have not already been
    # allocated at their new prison
    if AllocationVersion.where(
      nomis_offender_id: transfer.offender_no,
      prison: transfer.to_agency
    ).count > 0

      Rails.logger.info("Offender #{transfer.offender_no} was transferred but \
        an allocation at #{transfer.to_agency} already exists")

      return false
    end

    Rails.logger.info("Processing transfer for #{transfer.offender_no}")

    return false unless should_process?(transfer.offender_no)

    AllocationVersion.deallocate_offender(transfer.offender_no,
                                          AllocationVersion::OFFENDER_TRANSFERRED)
    true
  end

  # When an offender is released, we can no longer rely on their
  # case information (in case they come back one day), and we
  # should de-activate any current allocations.
  def self.process_release(release)
    return false unless release.to_agency == 'OUT' && release.from_prison?

    Rails.logger.info("Processing release for #{release.offender_no}")
    CaseInformationService.delete_information(release.offender_no)
    AllocationVersion.deallocate_offender(release.offender_no,
                                          AllocationVersion::OFFENDER_RELEASED)

    true
  end

  def self.should_process?(offender_no)
    OffenderService.get_offender(offender_no).convicted?
  end
end
