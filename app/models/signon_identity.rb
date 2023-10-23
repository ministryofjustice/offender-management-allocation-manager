# frozen_string_literal: true

class SignonIdentity
  class << self
    def from_omniauth(omniauth_data)
      return nil if omniauth_data.blank?

      new(omniauth_data)
    end
  end

  def initialize(omniauth_data)
    @username = omniauth_data.fetch('info').username
    @token = omniauth_data.fetch('credentials').token
    @active_caseload = omniauth_data.fetch('info').active_caseload
    @caseloads = omniauth_data.fetch('info').caseloads
    @expiry = omniauth_data.fetch('credentials').expires_at
    @roles = omniauth_data.fetch('info').roles
  end

  def attributes
    {
      username: @username,
      token: @token,
      active_caseload: @active_caseload,
      caseloads: @caseloads,
      expiry: @expiry,
      roles: @roles
    }
  end
end
