class AllocationsController < ApplicationController
  before_action :authenticate_user

  def index
    response = OffenderService.new.get_offenders_for_prison(
      caseload,
      page_number: page_number
    )

    @offenders_allocated = response.data
    @offenders_awaiting_allocation = response.data
    @offenders_awaiting_tiering = response.data

    @page_data = response.meta
  end
end
