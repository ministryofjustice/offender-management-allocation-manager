# frozen_string_literal: true

class ApiController < ApplicationController
  before_action :verify_token

  def index
    render json: { status: 'ok' }
  end

private

  def render_error(msg)
    render json: { status: 'error', message: msg }
  end

  def verify_token
    access_token = parse_access_token(request.headers['AUTHORIZATION'])

    token = Nomis::Oauth::Token.new(access_token: access_token)
    unless token.valid_token_with_scope?('read')
      render_error('Invalid token')
    end
  end

  def parse_access_token(auth_header)
    return nil if auth_header.nil?
    return nil unless auth_header.starts_with?('Bearer')

    auth_header.split.last
  end
end
