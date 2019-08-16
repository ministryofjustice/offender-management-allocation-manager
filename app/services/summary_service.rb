# frozen_string_literal: true

class SummaryService
  PAGE_SIZE = 20 # The number of items to show in the view

  class SummaryParams
    attr_reader :sort_field, :sort_direction

    def initialize(sort_field: nil, sort_direction: :asc)
      @sort_field = sort_field
      @sort_direction = sort_direction
    end
  end

  # rubocop:disable Metrics/MethodLength
  # rubocop:disable Metrics/LineLength
  # rubocop:disable Metrics/PerceivedComplexity
  # rubocop:disable Metrics/CyclomaticComplexity
  def self.summary(summary_type, prison, page, params)
    # We expect to be passed summary_type, which is one of :allocated, :unallocated,
    # or :pending.  The other types will return totals, and do not contain any data.
    bucket = Bucket.new

    # We want to store the total number of each item so we can show totals for
    # each type of record.
    counts = { allocated: 0, unallocated: 0, pending: 0, all: 0 }

    offenders = OffenderService.get_offenders_for_prison(prison)
    active_allocations_hash = AllocationService.allocations(offenders.map(&:offender_no), prison)

    offenders.each do |offender|
      if offender.tier.present?
        # When trying to determine if this offender has a current allocation, we want to know
        # if it is for this prison.  If the offender was recently transferred here their prison
        # field should be nil, which means they will be pending allocation.  Once they are allocated
        # the prison will be set on their existing allocation.
        if active_allocations_hash.key?(offender.offender_no)
          bucket.items << offender if summary_type == :allocated
          counts[:allocated] += 1
        else
          bucket.items << offender if summary_type == :unallocated
          counts[:unallocated] += 1
        end
      else
        counts[:pending] += 1
        bucket.items << offender if summary_type == :pending
      end
    end

    page_count = (counts[summary_type] / PAGE_SIZE.to_f).ceil

    # If we are on the last page, we don't always want 10 items from the bucket
    # we just want the last digit, so if there are 138 items, the last page should
    # show 8.
    wanted_items = number_items_wanted(
      page_count == page,
      counts[summary_type].digits[0]
    )
    if params.sort_field.present?
      bucket.sort(params.sort_field, params.sort_direction)
    end

    from = [(PAGE_SIZE * (page - 1)), 0].max

    # For the allocated offenders, we need to provide the allocated POM's
    # name
    offender_items = bucket.take(wanted_items, from) || []

    if summary_type == :allocated
      offender_items.each { |offender|
        alloc = active_allocations_hash[offender.offender_no]
        offender.allocated_pom_name = restructure_pom_name(alloc.primary_pom_name)
        offender.allocation_date = alloc.primary_pom_allocated_at
      }
    end

    Summary.new(summary_type).tap { |summary|
      summary.offenders = offender_items

      summary.allocated_total = counts[:allocated]
      summary.unallocated_total = counts[:unallocated]
      summary.pending_total = counts[:pending]

      summary.page_count = page_count
    }
  end
# rubocop:enable Metrics/CyclomaticComplexity
# rubocop:enable Metrics/LineLength
# rubocop:enable Metrics/MethodLength
# rubocop:enable Metrics/PerceivedComplexity

private

  def self.restructure_pom_name(pom_name)
    name = pom_name.titleize
    return name if name.include? ','

    parts = name.split(' ')
    "#{parts[1]}, #{parts[0]}"
  end

  def self.number_items_wanted(is_last_page, last_digit_of_count)
    if is_last_page && last_digit_of_count != 0
      last_digit_of_count
    else
      PAGE_SIZE
    end
  end
end
