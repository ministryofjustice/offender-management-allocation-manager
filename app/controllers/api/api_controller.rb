# frozen_string_literal: true

module Api
  class ApiController < ApplicationController
    before_action :verify_token

    def index
      render json: { status: 'ok' }
    end

    def render_404(msg)
      render json:  { status: 'error', message: msg }, status: :not_found
    end

  private

    def render_error(msg)
      render json: { status: 'error', message: msg }, status: :unauthorized
    end

    def verify_token
      access_token = parse_access_token(request.headers['AUTHORIZATION'])

      token = Nomis::Oauth::Token.new(access_token: access_token)
      unless token.valid_token_with_scope?('read')
        render_error('Valid authorisation token required')
      end
    end

    def parse_access_token(auth_header)
      return nil if auth_header.nil?
      return nil unless auth_header.starts_with?('Bearer')

      auth_header.split.last
    end
  end
end
