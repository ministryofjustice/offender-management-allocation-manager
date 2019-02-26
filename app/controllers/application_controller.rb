class ApplicationController < ActionController::Base
  helper_method :current_user
  helper_method :caseload

  include SSOIdentity

  def authenticate_user
    if sso_identity.nil? || session_expired?
      session[:redirect_path] = request.original_fullpath
      redirect_to '/auth/hmpps_sso'
    end
  end

  def current_user
    sso_identity['username'] if sso_identity.present?
  end

  def caseload
    sso_identity['caseload'] if sso_identity.present?
  end

private

  def session_expired?
    Time.current > Time.zone.at(sso_identity['expiry'])
  end
end
