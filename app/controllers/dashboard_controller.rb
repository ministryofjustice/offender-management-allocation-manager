class DashboardController < ApplicationController
  before_action :authenticate_user

  def index
    user = Nomis::Elite2::Api.fetch_nomis_user_details(current_user).data
    poms_list = PrisonOffenderManagerService.get_poms(caseload)
    @pom = poms_list.select { |p| p.staff_id.to_i == user.staff_id.to_i }.first
  end
end
