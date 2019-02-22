class DashboardController < ApplicationController
  before_action :authenticate_user

  def index
    @user = Nomis::Elite2::Api.fetch_nomis_user_details(current_user)
  end
end
