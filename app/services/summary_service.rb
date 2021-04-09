# frozen_string_literal: true

class SummaryService
  def initialize(summary_type, prison, sort_params = nil)
    @summary_type = summary_type

    # We expect to be passed summary_type, which is one of :allocated, :unallocated,
    # :pending, or :new_arrivals or :handovers. The other types will return totals, and do not contain
    # any data.
    sortable_fields = {
      allocated: [:last_name, :earliest_release_date, :tier, :allocation_date],
      new_arrivals: [:last_name, :prison_arrival_date, :earliest_release_date],
      handovers: [:last_name, :handover_start_date, :responsibility_handover_date, :case_allocation, :allocated_pom_name, :allocated_com_name],
      unallocated: [:last_name, :earliest_release_date, :case_owner, :awaiting_allocation_for, :tier],
      missing_information: [:last_name, :earliest_release_date, :case_owner, :awaiting_allocation_for, :tier]
    }.fetch(summary_type)

    # We want to store the total number of each item so we can show totals for
    # each type of record.
    @buckets = {
      allocated: [],
      unallocated: [],
      missing_information: [],
      new_arrivals: [],
      handovers: []
    }.merge(summary_type => Bucket.new(sortable_fields))

    offenders = prison.offenders
    active_allocations_hash = AllocationService.active_allocations(offenders.map(&:offender_no), prison.code)

    offenders.each do |offender|
      if offender.has_case_information?
        # When trying to determine if this offender has a current active allocation, we want to know
        # if it is for this prison.
        if active_allocations_hash.key?(offender.offender_no)
          @buckets.fetch(:allocated) << offender
        else
          @buckets.fetch(:unallocated) << offender
        end

        if offender.approaching_handover?
          @buckets.fetch(:handovers) << offender
        end
      elsif new_arrival?(offender)
        @buckets.fetch(:new_arrivals) << offender
      else
        @buckets.fetch(:missing_information) << offender
      end
    end

    add_allocated_poms_and_coms(@buckets[summary_type], active_allocations_hash)

    default_sort_params =
      { allocated: [nil, nil],
        unallocated: [:sentence_start_date, :asc],
        missing_information: [:sentence_start_date, :asc],
        new_arrivals: [:sentence_start_date, :asc],
        handovers: [:handover_start_date, :asc]
      }.fetch(summary_type)

    @sort_params = if sort_params
                     parts = sort_params.split.map { |s| s.downcase.to_sym }

                     if parts.second.blank?
                       parts + [:asc]
                     else
                       parts
                     end
                   else
                     default_sort_params
                   end
  end

  def offenders
    offenders_bucket = @buckets.fetch(@summary_type)
    offenders_bucket.sort_bucket! @sort_params[0], @sort_params[1]

    offenders_bucket
  end

  def unallocated
    @buckets.fetch(:unallocated)
  end

  def allocated
    @buckets.fetch(:allocated)
  end

  def pending
    @buckets.fetch(:missing_information)
  end

  def new_arrivals
    @buckets.fetch(:new_arrivals)
  end

  def handovers_total
    @buckets.fetch(:handovers).count
  end

private

  def new_arrival?(offender)
    offender.prison_arrival_date == Time.zone.today
  end

  def add_allocated_poms_and_coms(offenders, active_allocations_hash)
    offenders.each do |offender|
      next unless active_allocations_hash.key?(offender.offender_no)

      alloc = active_allocations_hash[offender.offender_no]

      # Add POM details
      offender.allocated_pom_name = restructure_pom_name(alloc.primary_pom_name)
      offender.allocation_date = (alloc.primary_pom_allocated_at || alloc.updated_at)&.to_date
    end
  end

  def restructure_pom_name(pom_name)
    name = pom_name.titleize
    return name if name.include? ','

    parts = name.split(' ')
    "#{parts[1]}, #{parts[0]}"
  end
end
