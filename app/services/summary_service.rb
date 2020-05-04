# frozen_string_literal: true

class SummaryService
  PAGE_SIZE = 20 # The number of items to show in the view
  def self.summary(summary_type, prison)
    # We expect to be passed summary_type, which is one of :allocated, :unallocated,
    # :pending, or :new_arrivals.  The other types will return totals, and do not contain
    # any data.
    sortable_fields = if summary_type == :allocated
                        sort_fields_for_allocated
                      elsif summary_type == :new_arrivals
                        sort_fields_for_new_arrivals
                      elsif summary_type == :handovers
                        sort_fields_for_handovers
                      else
                        default_sortable_fields
                      end

    # We want to store the total number of each item so we can show totals for
    # each type of record.
    buckets = { allocated: Bucket.new(sortable_fields),
                unallocated: Bucket.new(sortable_fields),
                pending: Bucket.new(sortable_fields),
                new_arrivals: Bucket.new(sortable_fields),
                handovers: Bucket.new(sortable_fields)
    }

    offenders = prison.offenders
    active_allocations_hash = AllocationService.active_allocations(offenders.map(&:offender_no), prison.code)

    add_allocated_poms_and_coms(offenders, active_allocations_hash)

    # We need arrival dates for all offenders and all summary types because it is used to
    # detect new arrivals and so we would not be able to count them without knowing their
    # prison_arrival_date
    add_arrival_dates(offenders) if offenders.any?

    offenders.each do |offender|
      # Having a 'tier' is an alias for having a case information record
      if offender.tier.present?
        # When trying to determine if this offender has a current active allocation, we want to know
        # if it is for this prison.
        if active_allocations_hash.key?(offender.offender_no)
          buckets[:allocated].items << offender
        else
          buckets[:unallocated].items << offender
        end
      elsif new_arrival?(offender)
        buckets[:new_arrivals].items << offender
      else
        buckets[:pending].items << offender
      end

      if approaching_handover?(offender)
        buckets[:handovers].items << offender
      end
    end

    Summary.new(summary_type, buckets)
  end




private

  def self.new_arrival?(offender)
    if Time.zone.today.monday?
      offender.awaiting_allocation_for <= 2
    else
      offender.prison_arrival_date.to_date == Time.zone.today
    end
  end

  def self.approaching_handover?(offender)
    today = Time.zone.today
    thirty_days_time = today + 30.days

    start_date = offender.handover_start_date
    handover_date = offender.responsibility_handover_date

    return false if start_date.nil?

    if start_date.future?
      start_date.between?(today, thirty_days_time)
    else
      today.between?(start_date, handover_date)
    end
  end

  def self.sort_fields_for_allocated
    [:last_name, :earliest_release_date, :tier]
  end

  def self.sort_fields_for_new_arrivals
    [:last_name, :prison_arrival_date, :earliest_release_date]
  end

  def self.sort_fields_for_handovers
    [:last_name, :handover_start_date, :responsibility_handover_date, :case_allocation]
  end

  def self.default_sortable_fields
    [:last_name, :earliest_release_date, :awaiting_allocation_for, :tier]
  end

  def self.add_arrival_dates(offenders)
    movements = Nomis::Elite2::MovementApi.admissions_for(offenders.map(&:offender_no))

    offenders.each do |offender|
      arrival = movements.fetch(offender.offender_no, []).reverse.detect { |movement|
        movement.to_agency == offender.prison_id
      }
      offender.prison_arrival_date = [offender.sentence_start_date, arrival&.create_date_time].compact.max
    end
  end

  def self.add_allocated_poms_and_coms(offenders, active_allocations_hash)
    offenders.each do |offender|
      next unless active_allocations_hash.key?(offender.offender_no)

      alloc = active_allocations_hash[offender.offender_no]

      # Add POM details
      offender.allocated_pom_name = restructure_pom_name(alloc.primary_pom_name)
      offender.allocation_date = (alloc.primary_pom_allocated_at || alloc.updated_at)&.to_date

      # Add COM details
      offender.allocated_com_name = alloc.com_name
    end
  end

  def self.restructure_pom_name(pom_name)
    name = pom_name.titleize
    return name if name.include? ','

    parts = name.split(' ')
    "#{parts[1]}, #{parts[0]}"
  end
end
