class ErrorsController < ApplicationController
  def not_found
    render(status: 404)
  end

  def unauthorized
    render(status: 401)
  end

  def internal_server_error
    render(status: 500)
  end
end
