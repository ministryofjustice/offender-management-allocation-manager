# frozen_string_literal: true

class ErrorsController < ApplicationController
  # Errors need to not have the dashboard link in the header
  layout 'errors_and_contact'

  def not_found
    render(status: :not_found)
  end

  def unauthorized
    render(status: :unauthorized)
  end

  def internal_server_error
    render(status: :internal_server_error)
  end
end
