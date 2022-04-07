# frozen_string_literal: true

class SessionsController < ApplicationController

  def create

    if session[:oauth_state] != params[:state]
      raise StandardError 'Invalid oauth state'
    end

    access_token = HmppsSso.get_token(params[:code])
    identity = HmppsSso.get_session(access_token)

    if identity
      save_to_session(:sso_data, identity)
      session.delete(:oauth_state)
      redirect_to session.delete(:redirect_path) || root_url
    else
      redirect_to root_url
    end
  end

  def destroy
    session.delete(:sso_data)
    redirect_to sso_signout_url
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
