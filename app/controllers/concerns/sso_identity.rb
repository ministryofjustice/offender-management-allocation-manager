module SsoIdentity
  extend ActiveSupport::Concern

  def sso_identity
    @sso_identity ||= session[:sso_data]
  end
end
