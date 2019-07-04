# frozen_string_literal: true

class DashboardController < ApplicationController
  before_action :authenticate_user

  def index
    @is_pom = PrisonOffenderManagerService.get_signed_in_pom_details(
      current_user, active_prison
    ).present?
    @prison = active_prison
  end

private
  def active_prison
    params[:prison_id]
  end
end
