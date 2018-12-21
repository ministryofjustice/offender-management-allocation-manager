class SignonIdentity
  class << self
    def from_omniauth(omniauth_data)
      new(omniauth_data)
    end
  end

  def initialize(omniauth_data)
    @username = omniauth_data.fetch('info').username
    @caseload = omniauth_data.fetch('info').caseload
    @expiry = omniauth_data.fetch('credentials').expires_at
  end

  def to_session
    {
      username: @username,
      caseload: @caseload,
      expiry: @expiry
    }
  end
end
