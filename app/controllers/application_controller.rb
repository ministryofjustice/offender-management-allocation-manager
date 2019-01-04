class ApplicationController < ActionController::Base
  helper_method :current_user

  include SSOIdentity

  def authenticate_user
    if sso_identity.nil? || session_expired?
      session[:redirect_path] = request.original_fullpath
      redirect_to '/auth/hmpps_sso'
    end
  end

  def current_user
    sso_identity['username']
  end

  def caseload
    sso_identity['caseload']
  end

  def page_number
    page_num = params.fetch('page', '1').to_i
    [page_num - 1, 0].max
  end

private

  def session_expired?
    Time.current > Time.zone.at(sso_identity['expiry'])
  end
end
