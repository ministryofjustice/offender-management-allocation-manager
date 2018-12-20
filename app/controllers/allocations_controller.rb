class AllocationsController < ApplicationController
  before_action :authenticate_user
  breadcrumb 'Allocations', :allocations_path

  def index
    @prisoners = Nomis::Custody::Api.get_offenders(caseload)
  end
end
