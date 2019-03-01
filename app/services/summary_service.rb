class SummaryService
  PAGE_SIZE = 10 # The number of items to show in the view
  FETCH_SIZE = 200 # How many records to fetch from nomis at a time

  # rubocop:disable Metrics/MethodLength
  # rubocop:disable Metrics/PerceivedComplexity
  # rubocop:disable Metrics/CyclomaticComplexity
  def summary(summary_type, prison, page, sort_field: nil, sort_direction: :asc)
    # We expect to be passed summary_type, which is one of :allocated, :unallocated,
    # or :pending.  The other types will return totals, and do not contain any data.
    bucket = Bucket.new

    # We want to store the total number of each item so we can show totals for
    # each type of record.
    @counts = { allocated: 0, unallocated: 0, pending: 0 }

    tier_map = CaseInformationService.get_case_information(prison)

    number_of_requests = max_requests_count(prison)
    (0..number_of_requests).each do |request_no|
      offenders = get_page_of_offenders(prison, request_no, tier_map)
      break if offenders.blank?

      # Group the offenders without a tier, and the remaining ones
      # are either allocated or unallocated
      tiered_offenders = get_tiered_offenders(offenders, bucket, summary_type == :pending)

      # Check the allocations for the remaining offenders who have tiers.
      offender_nos = tiered_offenders.map(&:offender_no)
      active_allocations_hash = AllocationService.active_allocations(offender_nos)

      # Put the offenders in the correct group based on whether we were able to
      # find an active allocation for them.
      tiered_offenders.each { |offender|
        if active_allocations_hash.key?(offender.offender_no)
          bucket << offender if summary_type == :allocated
          @counts[:allocated] += 1
        else
          bucket << offender if summary_type == :unallocated
          @counts[:unallocated] += 1
        end
      }
    end

    page_count = (@counts[summary_type] / PAGE_SIZE.to_f).ceil

    # If we are on the last page, we don't always want 10 items from the bucket
    # we just want the last digit, so if there are 138 items, the last page should
    # show 8.
    wanted_items = number_items_wanted(
      page_count == page,
      @counts[summary_type].digits[0]
    )
    if sort_field.present?
      bucket.sort(sort_field, sort_direction)
    end

    # For the allocated offenders, we need to provide the allocated POM's
    # name
    from = [(PAGE_SIZE * (page - 1)), 0].max

    if summary_type == :allocated
      offender_items = OffenderService.set_allocated_pom_name(
        bucket.take(wanted_items, from) || [],
        prison
      )
    else
      offender_items = bucket.take(wanted_items, from) || []
    end

    # Return the last (N) records from each bucket, in case
    # the capacity was higher than 10 (we need more than one page worth).
    Summary.new.tap { |summary|
      summary.offenders = offender_items

      summary.allocated_total = @counts[:allocated]
      summary.unallocated_total = @counts[:unallocated]
      summary.pending_total = @counts[:pending]

      summary.page_count = page_count
    }
  end
# rubocop:enable Metrics/CyclomaticComplexity
# rubocop:enable Metrics/MethodLength
# rubocop:enable Metrics/PerceivedComplexity

private

  def max_requests_count(prison)
    # Fetch the first 1 prisoners just for the total number of pages so that we
    # can send batched queries.
    info_request = Nomis::Elite2::OffenderApi.list(prison, 1, page_size: 1)

    # The maximum number of pages we need to fetch before we have all of
    # the offenders
    (info_request.meta.total_pages / FETCH_SIZE) + 1
  end

  def get_page_of_offenders(prison, page_number, tiers)
    OffenderService.get_offenders_for_prison(
      prison,
      page_number: page_number,
      page_size: FETCH_SIZE,
      tier_map: tiers
    )
  end

  def get_tiered_offenders(offender_list, bucket, store)
    # Filter out any offenders who have no tiering information
    # at the same time we add them to the correct bucket.
    offender_list.select { |offender|
      if offender.tier.blank?
        bucket << offender if store
        @counts[:pending] += 1
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
