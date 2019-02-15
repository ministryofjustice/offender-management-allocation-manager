class DashboardController < ApplicationController
  before_action :authenticate_user

  def index
    @pom = PrisonOffenderManagerService.get_signed_in_pom_details(current_user)
  end
end
