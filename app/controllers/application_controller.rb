# frozen_string_literal: true

class ApplicationController < ActionController::Base
  helper_method :current_user
  helper_method :caseloads, :current_user_is_spo?, :current_user_is_pom?

  before_action :set_paper_trail_whodunnit

  include SsoIdentity

  def authenticate_user
    if sso_identity.nil? || session_expired?
      session[:redirect_path] = request.original_fullpath
      redirect_to '/auth/hmpps_sso'
    else
      redirect_to '/401' unless allowed?
    end
  end

  def current_user
    sso_identity['username'] if sso_identity.present?
  end

  def current_user_is_spo?
    roles.include?('ROLE_ALLOC_MGR')
  end

  def current_user_is_pom?
    roles.include?('ROLE_ALLOC_CASE_MGR')
  end

  def ensure_admin_user
    unless current_user_is_spo?
      redirect_to '/'
    end
  end

  def ensure_case_admin_user
    unless current_user_is_pom?
      redirect_to '/'
    end
  end

  def default_prison_code
    sso_identity['active_caseload'] if sso_identity.present?
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
