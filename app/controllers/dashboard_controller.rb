# frozen_string_literal: true

class DashboardController < PrisonsApplicationController
  def index
    @unallocated_cases_count = @prison.unallocated.count
    @missing_details_cases_count = @prison.missing_info.count
    @case_updates_needed_count = @current_user.allocations.map(&:pom_tasks).flatten.count
  end
end
