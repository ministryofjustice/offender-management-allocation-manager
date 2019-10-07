# frozen_string_literal: true

class ApiController < ApplicationController
  before_action :verify_token

  def index
    render json: { status: 'ok' }
  end

private

  def verify_token
    access_token = parse_access_token(request.headers['AUTHORIZATION'])

    if valid_token?(access_token)
      true
    else
      render json: { status: 'error' }
    end
  end

  def parse_access_token(auth_header)
    return nil if auth_header.nil?

    return nil unless auth_header.starts_with?('Bearer')

    auth_header.split.last
  end

  def valid_token?(access_token)
    return false if Nomis::Oauth::Token.new(access_token: access_token).expired?

    if Nomis::Oauth::Token.new(access_token: access_token).valid_token?
      true
    else
      false
    end
  rescue JWT::DecodeError
    false
  end
end
