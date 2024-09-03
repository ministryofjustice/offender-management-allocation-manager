class ErrorsController < ApplicationController
  def not_found
    respond_with_status(:not_found)
  end

  def unauthorized
    respond_with_status(:unauthorized)
  end

  def internal_server_error
    respond_with_status(:internal_server_error)
  end

private

  def respond_with_status(status)
    respond_to do |format|
      format.html { render status: }
      format.all  { head status }
    end
  end
end
