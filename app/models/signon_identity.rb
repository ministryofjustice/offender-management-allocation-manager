# frozen_string_literal: true

class SignonIdentity
  class << self
    def from_omniauth(omniauth_data)
      return nil if omniauth_data.blank?

      new(omniauth_data)
    end
  end

  def initialize(omniauth_data)
    info = omniauth_data.fetch('info')

    @username = info.username
    @staff_id = info.staff_id
    @first_name = info.first_name if info.respond_to?(:first_name)
    @last_name = info.last_name if info.respond_to?(:last_name)
    @token = omniauth_data.fetch('credentials').token
    @active_caseload = info.active_caseload
    @caseloads = info.caseloads
    @expiry = omniauth_data.fetch('credentials').expires_at
    @roles = info.roles
  end

  def attributes
    {
      username: @username,
      staff_id: @staff_id,
      first_name: @first_name,
      last_name: @last_name,
      token: @token,
      active_caseload: @active_caseload,
      caseloads: @caseloads,
      expiry: @expiry,
      roles: @roles
    }
  end
end
