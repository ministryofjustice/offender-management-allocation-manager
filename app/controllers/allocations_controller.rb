class AllocationsController < ApplicationController
  before_action :authenticate_user

  def index
    allocated
    render 'allocated'
  end

  def allocated
    breadcrumb 'Allocated', :allocations_allocated_path

    response = Nomis::Elite2::Api.get_offender_list(caseload, page_number)
    @prisoners = response.data
    @page_data = response.meta
  end

  def awaiting
    breadcrumb 'Awaiting allocation', :allocations_awaiting_path

    response = Nomis::Elite2::Api.get_offender_list(caseload, page_number)
    @prisoners = response.data
    @page_data = response.meta
  end

  def missing_information
    breadcrumb 'Awaiting tiering', :allocations_missing_information_path

    response = Nomis::Elite2::Api.get_offender_list(caseload, page_number)
    @prisoners = response.data
    @page_data = response.meta
  end
end
