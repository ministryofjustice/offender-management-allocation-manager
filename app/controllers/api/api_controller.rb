# frozen_string_literal: true

module Api
  class ApiController < ApplicationController
    before_action :verify_token

    API_ROLE = 'ROLE_VIEW_POM_ALLOCATIONS'

    def index
      render json: { status: 'ok' }
    end

  private

    def render_404(message = 'Not found')
      render_error(message, :not_found)
    end

    def unauthorized_error(exception)
      render_error(exception.message, :unauthorized)
    end

    def render_error(message, status)
      render json: { status: 'error', message: }, status:
    end

    def verify_token
      unless token.valid_token_with_scope?('read', role: API_ROLE)
        render_error('Valid authorisation token required', :unauthorized)
      end
    end

    def token
      access_token = parse_access_token(request.headers['AUTHORIZATION'])
      HmppsApi::Oauth::Token.new(access_token: access_token)
    end

    def parse_access_token(auth_header)
      return nil if auth_header.nil?
      return nil unless auth_header.starts_with?('Bearer')

      auth_header.split.last
    end
  end
end
