class ApplicationController < ActionController::Base
  helper_method :current_user
  helper_method :active_caseload
  helper_method :caseloads

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

  def active_caseload
    sso_identity['active_caseload'] if sso_identity.present?
  end

  def update_active_caseload(code)
    session[:sso_data]['active_caseload'] = code
  end

  def caseloads
    return nil if sso_identity.blank?

    caseloads = sso_identity['caseloads']
    caseloads.reject { |c| c == 'NWEB' }
  end

private

  def session_expired?
    Time.current > Time.zone.at(sso_identity['expiry'])
  end
end
