# frozen_string_literal: true

class CaseloadHandoversController < PrisonStaffApplicationController
  include Sorting

  def index
    collection = sort_collection(@pom.allocations.select(&:approaching_handover?), default_sort: :last_name)

    @offenders = Kaminari.paginate_array(collection).page(page)
    @pending_handover_count = collection.count
    @prison_total_handovers = SummaryService.new(:handovers, @prison).handovers_total
  end
end
