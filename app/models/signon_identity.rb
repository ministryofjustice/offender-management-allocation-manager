class SignonIdentity
  class << self
    def from_omniauth(omniauth_data)
      user_auth_data = omniauth_data.fetch('info')
      new(user_auth_data)
    end
  end

  def initialize(user_auth_data)
    @username = user_auth_data.username
    @caseload = user_auth_data.caseload
  end

  def to_session
    {
      username: @username,
      caseload: @caseload
    }
  end
end
