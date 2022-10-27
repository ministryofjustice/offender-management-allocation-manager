class FeatureFlagsController < ApplicationController
  skip_forgery_protection

  def activate_new_handovers_ui
    unless params[:token] == NEW_HANDOVER_TOKEN
      redirect_to '/401'
      return
    end

    session[:new_handovers_ui] = true
    render json: '{"message": "New handovers UI activated"}'
  end
end
