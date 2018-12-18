class AllocationsController < ApplicationController
  before_action :authenticate_user

  def index
    @prisoners = Nomis::Custody::Api.get_offenders(caseload)
  end
end
