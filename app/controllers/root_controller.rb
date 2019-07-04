# frozen_string_literal: true

class RootController < ApplicationController
  before_action :authenticate_user

  def index
    redirect_to prison_dashboard_index_path(default_prison_code)
  end
end