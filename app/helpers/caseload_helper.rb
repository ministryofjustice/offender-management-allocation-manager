module CaseloadHelper
  def filtered_allocations(allocations, _filter_types)
    # Filters the allocations, returning only those that
    # match the named filters.
    allocations
  end

  # rubocop:disable Metrics/MethodLength
  def filter_facets(allocations)
    # Provided a list of allocations, returns a hash of the
    # number of allocations matching a specific filter.  It is
    # intended that this will show facets for the currently filtered
    # allocations, so the numbers will be different based on which
    # filters were used to generate the allocations list
    facets = CaseloadFilters.constants.map { |c|
      [CaseloadFilters.const_get(c), 0]
    }.to_h

    one_month_time = Time.zone.today + 30.days

    allocations.each do |allocation|
      if allocation.new_case?
        facets[CaseloadFilters::NEW_ALLOCATION] += 1
      else
        facets[CaseloadFilters::OLD_ALLOCATION] += 1
      end

      if allocation.offender.handover_start_date[0].nil?
        facets[CaseloadFilters::HANDOVER_UNKNOWN] += 1
      elsif allocation.offender.handover_start_date[0].between?(Time.zone.today, one_month_time)
        facets[CaseloadFilters::HANDOVER_STARTS_SOON] += 1
      elsif allocation.offender.handover_start_date[0] < Time.zone.today
        facets[CaseloadFilters::HANDOVER_IN_PROGRESS] += 1
      end

      if allocation.responsibility == 'Responsible'
        facets[CaseloadFilters::ROLE_RESPONSIBLE] += 1
      elsif allocation.responsibility == 'Supporting'
        facets[CaseloadFilters::ROLE_SUPPORTING] += 1
      else
        facets[CaseloadFilters::ROLE_COWORKING] += 1
      end
    end

    facets
  end
  # rubocop:enable Metrics/MethodLength
end
