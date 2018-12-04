class ApplicationController < ActionController::Base
  helper_method :current_user

  include SSOIdentity

  def authenticate_user
    unless sso_identity
      session[:redirect_path] = request.original_fullpath
      redirect_to '/auth/hmpps_sso'
    end
  end

  def current_user
    sso_identity['username']
  end
end
