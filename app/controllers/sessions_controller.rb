# frozen_string_literal: true

class SessionsController < ApplicationController
  def create
    identity = SignonIdentity.from_omniauth(request.env['omniauth.auth'])

    if identity
      save_to_session(:sso_data, identity)
      redirect_to session.delete(:redirect_path) || root_url
    else
      redirect_to root_url
    end
  end

  def destroy
    session.delete(:sso_data)
    redirect_to sso_signout_url, allow_other_host: true
  end

  def failure
    render(status: :unauthorized)
  end

private

  def sso_signout_url
    url = URI.parse("#{Rails.configuration.nomis_oauth_host}/auth/logout")
    url.query = {
      redirect_uri: Rails.configuration.allocation_manager_host,
      client_id: Rails.configuration.hmpps_oauth_client_id
    }.to_query

    url.to_s
  end
end
