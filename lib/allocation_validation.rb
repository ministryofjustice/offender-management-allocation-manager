# frozen_string_literal: true

class AllocationValidation
  def self.fixup(prison)
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
    allocations = Prison.find(prison).allocations

    puts "Processing #{allocations.count} items"

    allocations.each do |allocation|
      # Get the offender from NOMIS
      offender = OffenderService.get_offender(allocation.nomis_offender_id)
      if offender.nil?
        puts "Can't find offender #{allocation.nomis_offender_id} - probably merged, deallocating"
        allocation.deallocate_offender_after_release
        next
      end

      if offender.sentenced? == false
        # This offender should not have any case information, and should not
        # be allocated to anybody We will de-allocate the offender so they can
        # be re-allocated against a new offense.
        puts "#{offender.offender_no} is not sentenced - deallocating"
        allocation.deallocate_offender_after_release
        next
      end

      # If the offender is at this prison, we're good .
      next if offender.prison_id == prison

      # If the offender is out, deallocate as a release
      if offender.prison_id == 'OUT'
        puts "#{offender.offender_no} appears to have been released - deallocating"
        allocation.deallocate_offender_after_release
        next
      end

      # The offender is at a different prison so deallocate as a transfer
      puts "#{offender.offender_no} (allocated) appears to have been transferred to #{offender.prison_id} - deallocating"
      allocation.deallocate_offender_after_transfer
    end
  end
end
