# frozen_string_literal: true

class SummaryService
  PAGE_SIZE = 10 # The number of items to show in the view

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

    OffenderService.get_offenders_for_prison(prison).each do |offender|
      if offender.tier.present?
        active_allocations_hash = AllocationService.allocations([offender.offender_no], prison)
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
    if summary_type == :allocated
      offender_items = OffenderService.set_allocated_pom_name(
        bucket.take(wanted_items, from) || [],
        prison
      )
    else
      offender_items = bucket.take(wanted_items, from) || []
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

  def self.number_items_wanted(is_last_page, last_digit_of_count)
    if is_last_page && last_digit_of_count != 0
      last_digit_of_count
    else
      PAGE_SIZE
    end
  end
end
