class AllocationsController < ApplicationController
  before_action :authenticate_user

  def index
    allocated_page = params.fetch('allocated_page', 1).to_i
    unallocated_page = params.fetch('unallocated_page', 1).to_i
    missing_info_page = params.fetch('missing_info_page', 1).to_i

    @summary = AllocationSummaryService.summary(
      allocated_page,
      unallocated_page,
      missing_info_page,
      caseload
    )

    @page_data = PageMeta.new
  end
end
