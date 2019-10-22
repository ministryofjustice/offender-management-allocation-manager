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
  # rubocop:disable Metrics/PerceivedComplexity
  # rubocop:disable Metrics/CyclomaticComplexity
  def self.summary(summary_type, prison, page, params)
    # We expect to be passed summary_type, which is one of :allocated, :unallocated,
    # or :pending.  The other types will return totals, and do not contain any data.
    bucket = Bucket.new

    # We want to store the total number of each item so we can show totals for
    # each type of record.
    counts = { allocated: 0, unallocated: 0, pending: 0 }

    offenders = OffenderService.get_offenders_for_prison(prison)
    active_allocations_hash = AllocationService.active_allocations(offenders.map(&:offender_no), prison)

    offenders.each do |offender|
      if offender.tier.present?
        # When trying to determine if this offender has a current active allocation, we want to know
        # if it is for this prison.
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

    if params.sort_field.present?
      unless summary_type == :allocated
        add_arrival_dates(bucket.items) if bucket.items.any?
      end
      bucket.sort(params.sort_field, params.sort_direction)
    end

    # For the allocated offenders, we need to provide the allocated POM's
    # name
    if summary_type == :allocated
      bucket.items.each { |offender|
        alloc = active_allocations_hash[offender.offender_no]
        offender.allocated_pom_name = restructure_pom_name(alloc.primary_pom_name)
        offender.allocation_date = (alloc.primary_pom_allocated_at || alloc.updated_at)&.to_date
      }
    end

    Summary.new(summary_type).tap { |summary|
      offenders = bucket.items.map { |o| OffenderPresenter.new(o, nil) }

      summary.offenders = Kaminari.paginate_array(offenders).page(page)

      summary.allocated_total = counts[:allocated]
      summary.unallocated_total = counts[:unallocated]
      summary.pending_total = counts[:pending]
    }
  end
# rubocop:enable Metrics/CyclomaticComplexity
# rubocop:enable Metrics/MethodLength
# rubocop:enable Metrics/PerceivedComplexity

private

  def self.add_arrival_dates(offenders)
    movements = Nomis::Elite2::MovementApi.admissions_for(offenders.map(&:offender_no))

    offenders.each do |offender|
      arrival = movements[offender.offender_no].reverse.detect { |movement|
        movement.to_agency == offender.prison_id
      }
      offender.prison_arrival_date = [offender.sentence_start_date, arrival.create_date_time].compact.max
    end
  end

  def self.restructure_pom_name(pom_name)
    name = pom_name.titleize
    return name if name.include? ','

    parts = name.split(' ')
    "#{parts[1]}, #{parts[0]}"
  end
end
