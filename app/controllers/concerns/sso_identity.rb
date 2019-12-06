class SsoIdentity
  def initialize(session)
    @sso_identity = session[:sso_data]
  end

  def absent?
    @sso_identity.nil?
  end

  def current_user
    @sso_identity['username'] if @sso_identity.present?
  end

  def current_user_is_spo?
    roles.include?('ROLE_ALLOC_MGR')
  end

  def current_user_is_pom?
    roles.include?('ROLE_ALLOC_CASE_MGR')
  end

  # Ideally this would check some super-power - but it doesn't currently exist in C-NOMIS
  # we can't make ourselves POMs in production as we would show up in all the prisons :-(
  def admin?
    current_user_is_spo?
  end

  def default_prison_code
    @sso_identity['active_caseload'] if @sso_identity.present?
  end

  def caseloads
    if @sso_identity.blank?
      []
    else
      @sso_identity.fetch('caseloads').reject { |c| c.casecmp('NWEB') == 0 }
    end
  end

  def allowed?
    roles.include?('ROLE_ALLOC_MGR') || roles.include?('ROLE_ALLOC_CASE_MGR')
  end

  def session_expired?
    @sso_identity['expiry'] && Time.current > Time.zone.at(@sso_identity['expiry'])
  end

private

  def roles
    @roles ||= if @sso_identity.present? && @sso_identity['roles']
                 @sso_identity['roles']
               else
                 []
               end
  end
end
