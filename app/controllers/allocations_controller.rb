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

  def pending_allocation
    breadcrumb 'Awaiting allocation', :allocations_pending_path
    @prisoners = Nomis::Custody::Api.get_offenders(caseload)
  end

  def pending_tier
    breadcrumb 'Awaiting tiering', :allocations_waiting_path
    @prisoners = Nomis::Custody::Api.get_offenders(caseload)
  end
end
