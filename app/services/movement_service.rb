# frozen_string_literal: true

class MovementService
  # rubocop:disable Metrics/MethodLength
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
  # rubocop:enable Metrics/MethodLength

  def self.process_movement(movement)
    if movement.movement_type == Nomis::Models::MovementType::RELEASE
      return process_release(movement)
    end

    # We think that an ADM without a fromAgency is from court so there
    # will be nothing to delete/change.
    if movement.movement_type == Nomis::Models::MovementType::ADMISSION &&
        movement.direction_code == Nomis::Models::MovementDirection::IN &&
        movement.from_agency.present?
      return process_transfer(movement)
    end

    false
  end

private

  def self.process_transfer(transfer)
    Rails.logger.info("Processing transfer for #{transfer.offender_no}")

    Allocation.deallocate_offender(transfer.offender_no)
    CaseInformationService.change_prison(
      transfer.offender_no,
      transfer.from_agency,
      transfer.to_agency
    )

    true
  end

  # When an offender is released, we can no longer rely on their
  # case information (in case they come back one day), and we
  # should de-activate any current allocations.
  def self.process_release(release)
    Rails.logger.info("Processing release for #{release.offender_no}")
    CaseInformationService.delete_information(release.offender_no)
    Allocation.deallocate_offender(release.offender_no)

    true
  end
end
