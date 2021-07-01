# frozen_string_literal: true

class DashboardController < PrisonsApplicationController
  def index
    @unallocated_cases_count = @prison.unallocated.count
    @missing_details_cases_count = @prison.missing_info.count
  end
end
