class AllocationsController < ApplicationController
  before_action :authenticate_user

  def index
    allocated
    render 'allocated'
  end

  def allocated
    breadcrumb 'Allocated', :allocations_allocated_path

    response = Nomis::Custody::Api.get_offenders(caseload, page_number)
    @prisoners = response.data
  end

  def awaiting
    breadcrumb 'Awaiting allocation', :allocations_awaiting_path

    response = Nomis::Custody::Api.get_offenders(caseload, page_number)
    @prisoners = response.data
  end

  def missing_information
    breadcrumb 'Awaiting tiering', :allocations_missing_information_path

    response = Nomis::Custody::Api.get_offenders(caseload, page_number)
    @prisoners = response.data
  end
end
