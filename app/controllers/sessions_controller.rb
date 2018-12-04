class SessionsController < ApplicationController
  def create
    identity = SignonIdentity.from_omniauth(request.env['omniauth.auth'])

    if identity
      session[:sso_data] = identity.to_session
      redirect_to session.delete(:redirect_path) || root_url
    else
      redirect_to root_url
    end
  end
end
