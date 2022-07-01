class HandoverCaseListingService
  def counts
    # TODO
  end

  def upcoming(pom)
    # collection = sort_collection(@pom.allocations.select(&:approaching_handover?), default_sort: :last_name)
    #
    # @offenders = Kaminari.paginate_array(collection).page(page)
    # @pending_handover_count = collection.count
    # @prison_total_handovers = @prison.offenders.count(&:approaching_handover?)

    pom.allocations.select(&:in_upcoming_handover_window?)
  end

  def in_progress
    # TODO
  end

  def overdue_tasks
    # TODO
  end

  def com_allocation_overdue
    # TODO
  end
end
