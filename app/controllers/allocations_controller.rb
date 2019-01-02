class AllocationsController < ApplicationController
  before_action :authenticate_user

  def index
    allocated
    render 'allocated'
  end

  def allocated
    breadcrumb 'Allocated', :allocations_allocated_path
    @prisoners = Nomis::Custody::Api.get_offenders(caseload)
  end

  def awaiting
    breadcrumb 'Awaiting allocation', :allocations_awaiting_path
    @prisoners = Nomis::Custody::Api.get_offenders(caseload)
  end

  def missing_information
    breadcrumb 'Awaiting tiering', :allocations_missing_information_path
    @prisoners = Nomis::Custody::Api.get_offenders(caseload)
  end
end
