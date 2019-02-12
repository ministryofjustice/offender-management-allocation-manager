class AllocationSummaryService
  PAGE_SIZE = 10 # The number of items to show in the view
  FETCH_SIZE = 500 # How many records to fetch from nomis at a time

  # rubocop:disable Metrics/MethodLength
  def summary(allocated_page, unallocated_page, missing_info_page, prison)
    create_buckets(allocated_page, unallocated_page, missing_info_page)

    # We want to store the total number of each item so we can show totals for
    # each type of record.
    @counts = { allocated_count: 0, unallocated_count: 0, missing_count: 0 }

    number_of_requests = max_requests_count(prison)
    (0..number_of_requests).each do |request_no|
      offenders = get_page_of_offenders(prison, request_no)
      break if offenders.blank?

      # Group the offenders without a tier, and the remaining ones
      # are either allocated or unallocated
      tiered_offenders = get_tiered_offenders(offenders)

      # Check the allocations for the remaining offenders who have tiers.
      offender_nos = tiered_offenders.map(&:offender_no)
      active_allocations_hash = AllocationService.active_allocations(offender_nos)

      # Put the offenders in the correct group based on whether we were able to
      # find an active allocation for them.
      tiered_offenders.each { |offender|
        if active_allocations_hash.key?(offender.offender_no)
          @allocated_bucket << offender
          @counts[:allocated_count] += 1
        else
          @unallocated_bucket << offender
          @counts[:unallocated_count] += 1
        end
      }
    end

    allocated_page_count = (@counts[:allocated_count] / PAGE_SIZE.to_f).ceil
    unallocated_page_count = (@counts[:unallocated_count] / PAGE_SIZE.to_f).ceil
    missing_page_count = (@counts[:missing_count] / PAGE_SIZE.to_f).ceil

    # If we are on the last page, we don't always want 10 items from the bucket
    # we just want the last digit, so if there are 138 items, the last page should
    # show 8.
    allocated_wanted = number_items_wanted(
      allocated_page_count == allocated_page,
      @counts[:allocated_count].digits[0]
    )
    unallocated_wanted = number_items_wanted(
      allocated_page_count == allocated_page,
      @counts[:unallocated_count].digits[0]
    )
    missing_wanted = number_items_wanted(
      missing_page_count == missing_info_page,
      @counts[:missing_count].digits[0]
    )

    # Return the last (N) records from each bucket, in case
    # the capacity was higher than 10 (we need more than one page worth).
    AllocationSummary.new.tap { |summary|
      summary.allocated_offenders = @allocated_bucket.last(allocated_wanted)
      summary.unallocated_offenders = @unallocated_bucket.last(unallocated_wanted)
      summary.missing_info_offenders = @missing_info_bucket.last(missing_wanted)

      summary.allocated_total = @counts[:allocated_count]
      summary.unallocated_total = @counts[:unallocated_count]
      summary.missing_info_total = @counts[:missing_count]

      summary.allocated_page_count = allocated_page_count
      summary.unallocated_page_count = unallocated_page_count
      summary.missing_page_count = missing_page_count
    }
  end
# rubocop:enable Metrics/MethodLength

private

  def create_buckets(allocated_page, unallocated_page, missing_info_page)
    # Create buckets for each group.  The bucket will stop accepting items when
    # the capacity is full.  The capacity we need for each type is based on the currently
    # requested page.  If we want page 2 then we need 20 items, so we can use the last 10.
    @allocated_bucket = Bucket.new(allocated_page * PAGE_SIZE)
    @unallocated_bucket = Bucket.new(unallocated_page * PAGE_SIZE)
    @missing_info_bucket = Bucket.new(missing_info_page * PAGE_SIZE)
  end

  def max_requests_count(prison)
    # Fetch the first 1 prisoners just for the total number of pages so that we
    # can send batched queries.
    info_request = OffenderService.new.get_offenders_for_prison(
      prison,
      page_number: 0,
      page_size: 1
    )

    # The maximum number of pages we need to fetch before we have all of
    # the offenders
    (info_request.meta.total_pages / FETCH_SIZE) + 1
  end

  def get_page_of_offenders(prison, page_number)
    response = OffenderService.new.get_offenders_for_prison(
      prison,
      page_number: page_number,
      page_size: FETCH_SIZE
    )
    response.data
  end

  def get_tiered_offenders(offender_list)
    # Filter out any offenders who have no tiering information
    # at the same time we add them to the correct bucket.
    offender_list.select { |offender|
      if offender.tier.blank?
        @missing_info_bucket << offender
        @counts[:missing_count] += 1
        false
      else
        true
      end
    }
  end

  def number_items_wanted(is_last_page, last_digit_of_count)
    if is_last_page && last_digit_of_count != 0
      last_digit_of_count
    else
      PAGE_SIZE
    end
  end
end
