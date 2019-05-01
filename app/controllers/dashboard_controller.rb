# frozen_string_literal: true

class DashboardController < ApplicationController
  before_action :authenticate_user

  def index
    @is_pom = PrisonOffenderManagerService.get_signed_in_pom_details(
      current_user, active_caseload
    ).present?
  end
end
