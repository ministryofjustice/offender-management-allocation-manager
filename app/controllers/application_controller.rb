class ApplicationController < ActionController::Base
  helper_method :current_user
  helper_method :active_caseload
  helper_method :caseloads

  include SSOIdentity

  def authenticate_user
    if sso_identity.nil? || session_expired?
      session[:redirect_path] = request.original_fullpath
      redirect_to '/auth/hmpps_sso' && return
    end

    redirect_to '/401' unless roles.present? && roles.include?('ROLE_ALLOC_MGR')
  end

  def current_user
    sso_identity['username'] if sso_identity.present?
  end

  def active_caseload
    sso_identity['active_caseload'] if sso_identity.present?
  end

  def caseloads
    sso_identity['caseloads'] if sso_identity.present?
  end

  def roles
    sso_identity['roles'] if sso_identity.present?
  end

private

  def session_expired?
    Time.current > Time.zone.at(sso_identity['expiry'])
  end
end
