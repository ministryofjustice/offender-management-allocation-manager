# frozen_string_literal: true

class AllocationValidation
  # rubocop:disable Metrics/LineLength
  # rubocop:disable Rails/Output
  def fixup(prison)
    # Looks for offenders who have an allocation at this prison
    # who are allocated incorrectly because of a release or a transfer.
    #
    # Specifically it handles
    #
    # * Offender is currently allocated at this prison but was released
    # * Offender is currently allocated at this prison but was transferred
    #   This means that they will be available for allocation at their new
    #   prison until we deactivate the allocation at the old prison
    #

    # Get all active allocations for this prison
    allocations = active_allocations_for_prison(prison)

    puts "Processing #{allocations.count} items"

    allocations.each { |allocation|
      # Get the offender from NOMIS
      offender = OffenderService.get_offender(allocation.nomis_offender_id)

      # If the offender is at this prison, we're good .
      next if offender.latest_location_id == prison

      # If the offender is out, deallocate as a release
      if offender.latest_location_id == 'OUT'
        puts "#{offender.offender_no} appears to have been released"
        # AllocationVersion.deallocate_offender(offender.offender_no, 'offender_released')
        next
      end

      # The offender is at a different prison so deallocate as a transfer
      puts "#{offender.offender_no} (allocated) appears to have been transferred to #{offender.latest_location_id}"
      # AllocationVersion.deallocate_offender(offender.offender_no, 'offender_transferred')
    }
  end
  # rubocop:enable Metrics/LineLength
  # rubocop:enable Rails/Output

  def active_allocations_for_prison(prison)
    AllocationVersion.where.not(primary_pom_nomis_id: nil).where(prison: prison)
  end
end
