class SignonIdentity
  class << self
    def from_omniauth(omniauth_data)
      return nil if omniauth_data.blank?

      new(omniauth_data)
    end
  end

  def initialize(omniauth_data)
    @username = omniauth_data.fetch('info').username
    @active_caseload = omniauth_data.fetch('info').active_caseload
    @caseloads = omniauth_data.fetch('info').caseloads
    @expiry = omniauth_data.fetch('credentials').expires_at
    @roles = get_roles(omniauth_data.fetch('credentials'))
  end

  def get_roles(credentials)
    return ['ROLE_ALLOC_MGR'] if Rails.env.test?
    byebug
    public_key = Base64.urlsafe_decode64(
        Rails.configuration.nomis_oauth_public_key
    )

    decoded_token = JWT.decode(
        credentials.token,
        OpenSSL::PKey::RSA.new(public_key),
        true,
        algorithm: 'RS256'
    )

    decoded_token.first.fetch('authorities', [])
  end

  def to_session
    p @roles
    {
      username: @username,
      active_caseload: @active_caseload,
      caseloads: @caseloads,
      expiry: @expiry,
      roles: @roles
    }
  end
end
