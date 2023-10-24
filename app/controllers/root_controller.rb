# frozen_string_literal: true

class RootController < ApplicationController
  before_action :authenticate_user

  def index
    session.delete(:sso_data)
    redirect_to prison_dashboard_index_path(default_prison_code)
  end

  def handovers_email_preferences
    redirect_to prison_edit_handover_email_preferences_path(default_prison_code)
  end
end
