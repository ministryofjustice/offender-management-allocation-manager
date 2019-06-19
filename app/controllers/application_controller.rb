# frozen_string_literal: true

class ApplicationController < ActionController::Base
  helper_method :current_user
  helper_method :active_caseload
  helper_method :caseloads

  before_action :set_paper_trail_whodunnit

  include SSOIdentity

  def authenticate_user
    if sso_identity.nil? || session_expired?
      session[:redirect_path] = request.original_fullpath
      redirect_to '/auth/hmpps_sso'
    else
      redirect_to '/401' unless allowed?
    end
  end

  def ensure_pom
    pom = PrisonOffenderManagerService.get_signed_in_pom_details(
      current_user, active_caseload
    )

    if pom.blank?
      redirect_to '/'
    end
  end

  def current_user
    sso_identity['username'] if sso_identity.present?
  end

  def admin_user?
    r = roles
    unless r.present? && r.include?('ROLE_ALLOC_MGR')
      redirect_to '/'
    end
  end

  def case_admin_user?
    r = roles
    unless r.present? && r.include?('ROLE_ALLOC_CASE_MGR')
      redirect_to '/'
    end
  end

  def active_caseload
    sso_identity['active_caseload'] if sso_identity.present?
  end

  def update_active_caseload(code)
    session[:sso_data]['active_caseload'] = code
  end

  def roles
    sso_identity['roles'] if sso_identity.present?
  end

  def caseloads
    return nil if sso_identity.blank?

    caseloads = sso_identity['caseloads']
    caseloads.reject { |c| c.casecmp('NWEB') == 0 }
  end

private

  def allowed?
    user_roles = roles
    user_roles.present? && (
      user_roles.include?('ROLE_ALLOC_MGR') || user_roles.include?('ROLE_ALLOC_CASE_MGR')
    )
  end

  def session_expired?
    Time.current > Time.zone.at(sso_identity['expiry'])
  end
end
