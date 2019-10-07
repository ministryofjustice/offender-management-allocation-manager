# frozen_string_literal: true

class ApiController < ApplicationController
  before_action :verify_token

  def index
    render json: { status: 'ok' }
  end

private

  def verify_token
    access_token = parse_access_token(request.headers['AUTHORIZATION'])

    return render_error if no_token(access_token)

    return render_error unless expiry_key?(access_token)

    return render_error unless valid_scope?(access_token)

    true
  end

  def no_token(access_token)
    return true if access_token.nil?

    invalid_token?(access_token)
  end

  def render_error
    render json: { status: 'error' }
  end

  def parse_access_token(auth_header)
    return nil if auth_header.nil?

    return nil unless auth_header.starts_with?('Bearer')

    auth_header.split.last
  end

  def invalid_token?(access_token)
    if Nomis::Oauth::Token.new(access_token: access_token).expired?
      true
    else
      false
    end
  rescue JWT::DecodeError
    true
  end

  def expiry_key?(access_token)
    if Nomis::Oauth::Token.new(access_token: access_token).expiration_date?
      true
    else
      false
    end
  end

  def valid_scope?(access_token)
    if Nomis::Oauth::Token.new(access_token: access_token).read_scope?
      true
    else
      false
    end
  end
end
