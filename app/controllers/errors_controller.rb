class ErrorsController < ApplicationController
  before_action :report_exception, only: :internal_server_error

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

  def report_exception
    exception = request.env['action_dispatch.exception']
    return unless exception

    Rails.error.report(exception, handled: false, source: 'exceptions_app')
  end

  def respond_with_status(status)
    respond_to do |format|
      format.html { render status: }
      format.all  { head status }
    end
  end
end
