class AllocationSummaryService
  PAGE_SIZE = 10 # The number of items to show in the view
  FETCH_SIZE = 500 # How many records to fetch from nomis at a time

  # rubocop:disable Metrics/MethodLength
  def self.summary(allocated_page, unallocated_page, missing_info_page, prison)
    # Create buckets for each group.  The bucket will stop accepting items when
    # the capacity is full.  The capacity we need for each type is based on the currently
    # requested page.  If we want page 2 then we need 20 items, so we can use the last 10.
    allocated_bucket = Bucket.new(allocated_page * PAGE_SIZE)
    unallocated_bucket = Bucket.new(unallocated_page * PAGE_SIZE)
    missing_info_bucket = Bucket.new(missing_info_page * PAGE_SIZE)

    # We want to store the total number of each item so we can show totals for
    # each type of record.
    allocated_count = 0
    unallocated_count = 0
    missing_count = 0

    # Fetch the first 1 prisoners just for the total number of pages so that we
    # can send batched queries.
    info_request = OffenderService.new.get_offenders_for_prison(
      prison,
      page_number: 0,
      page_size: 1
    )

    # The maximum number of pages we need to fetch before we have all of
    # the offenders
    max_request_count = (info_request.meta.total_pages / FETCH_SIZE) + 1

    (0..max_request_count).each do |request_no|
      # Get the records for the desired page, with the desired size
      response = OffenderService.new.get_offenders_for_prison(
        prison,
        page_number: request_no,
        page_size: FETCH_SIZE
      )

      # If there are no more records, we're done.
      break if response.data.count == 0

      # Group the offenders without a tier, and the remaining ones
      # are either allocated or unallocated
      tiered_offenders = response.data.select { |offender|
        if offender.tier.blank?
          missing_info_bucket << offender
          missing_count += 1
          false
        else
          true
        end
      }

      # Check the allocations for the remaining offenders who have tiers.
      offender_nos = tiered_offenders.map(&:offender_no)
      active_allocations_hash = AllocationService.active_allocations(offender_nos)

      # Put the offenders in the correct group based on whether we were able to
      # find an active allocation for them.
      tiered_offenders.each { |offender|
        if active_allocations_hash.key?(offender.offender_no)
          allocated_bucket << offender
          allocated_count += 1
        else
          unallocated_bucket << offender
          unallocated_count += 1
        end
      }
    end

    allocated_page_count = (allocated_count / PAGE_SIZE.to_f).ceil
    unallocated_page_count = (unallocated_count / PAGE_SIZE.to_f).ceil
    missing_page_count = (missing_count / PAGE_SIZE.to_f).ceil

    # If we are on the last page, we don't always want 10 items from the bucket
    # we just want the last digit, so if there are 138 items, the last page should
    # show 8.
    allocated_wanted = PAGE_SIZE
    unallocated_wanted = PAGE_SIZE
    missing_wanted = PAGE_SIZE

    if allocated_page_count == allocated_page && allocated_count.digits[0] != 0
      allocated_wanted = allocated_count.digits[0]
    end

    if unallocated_page_count == unallocated_page && unallocated_count.digits[0] != 0
      unallocated_wanted = unallocated_count.digits[0]
    end

    if missing_page_count == missing_info_page && missing_count.digits[0] != 0
      missing_wanted = missing_count.digits[0]
    end

    # Return the last (N) records from each bucket, in case
    # the capacity was higher than 10 (we need more than one page worth).
    AllocationSummary.new.tap { |summary|
      summary.allocated_offenders = allocated_bucket.last(allocated_wanted)
      summary.unallocated_offenders = unallocated_bucket.last(unallocated_wanted)
      summary.missing_info_offenders = missing_info_bucket.last(missing_wanted)

      summary.allocated_total = allocated_count
      summary.unallocated_total = unallocated_count
      summary.missing_info_total = missing_count

      summary.allocated_page_count = allocated_page_count
      summary.unallocated_page_count = unallocated_page_count
      summary.missing_page_count = missing_page_count
    }
  end
  # rubocop:enable Metrics/MethodLength
end
