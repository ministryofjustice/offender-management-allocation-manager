class AllocationsController < ApplicationController
  before_action :authenticate_user

  def index
    allocated_page = params.fetch('allocated-page', 1).to_i
    unallocated_page = params.fetch('unallocated-page', 1).to_i
    missing_info_page = params.fetch('missing-info-page', 1).to_i

    @summary = AllocationSummaryService.summary(
      allocated_page, unallocated_page,
      missing_info_page, caseload
    )

    @allocated_page_meta = @summary.allocated_page_meta(allocated_page)
    @unallocated_page_meta = @summary.unallocated_page_meta(unallocated_page)
    @missing_info_page_meta = @summary.missing_info_page_meta(missing_info_page)
  end
end
