class AllocationsController < ApplicationController
  before_action :authenticate_user

  def index
    response = OffenderService.new.get_offenders_for_prison(
      caseload,
      page_number: page_number
    )

    offenders = response.data

    @offenders_allocated = offenders
    @offenders_awaiting_allocation = offenders
    @offenders_awaiting_tiering = offenders

    @page_data = response.meta
  end
end
