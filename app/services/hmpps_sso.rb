# frozen_string_literal: true

class HmppsSso
  include HmppsApi::Oauth::ClientHelper

  REDIRECT_BASE_URL = "#{Rails.application.config.allocation_manager_host}/auth/hmpps_sso/callback".freeze
  REDIRECT_URL = "#{REDIRECT_BASE_URL}&response_type=code&client_id=#{Rails.application.config.hmpps_oauth_client_id}".freeze
  CALLBACK = "#{Rails.application.config.nomis_oauth_host}/auth/oauth/authorize?redirect_uri=#{REDIRECT_URL}".freeze

  def self.get_callback(state)
    "#{CALLBACK}&state=#{state}"
  end

  def self.get_login_url
    client.auth_code.authorize_url(redirect_uri: REDIRECT_URL)
  end

  def self.get_token(code)
    client.auth_code.get_token(
      code,
      redirect_uri: REDIRECT_BASE_URL,
      headers: { 'Authorization' => "Basic #{Base64.urlsafe_encode64(
        "#{Rails.configuration.hmpps_oauth_client_id}:#{Rails.configuration.hmpps_oauth_client_secret}"
      )}" }
    ).token
  end

  def self.get_session(token)
    public_key = Base64.urlsafe_decode64(
      Rails.configuration.nomis_oauth_public_key
    )

    decoded_token = JWT.decode(
      token,
      OpenSSL::PKey::RSA.new(public_key),
      true,
      algorithm: 'RS256'
    ).first

    username = decoded_token.fetch('user_name')
    user_details = HmppsApi::PrisonApi::UserApi.user_details(username)
    user_details.nomis_caseloads = HmppsApi::PrisonApi::UserApi.user_caseloads(user_details.staff_id)
    caseload_codes = user_details.nomis_caseloads.map do |codes|
      codes['caseLoadId']
    end

    {
      username: username,
      active_caseload: user_details.active_case_load_id,
      caseloads: caseload_codes,
      expiry: decoded_token.fetch('exp'),
      roles: decoded_token.fetch('authorities', [])
    }

  end

private

  def self.client
    @client || (@client =
                  OAuth2::Client.new(Rails.configuration.hmpps_oauth_client_id,
                                     Rails.configuration.hmpps_oauth_client_secret,
                                     site: Rails.configuration.nomis_oauth_host,
                                     authorize_url: '/auth/sign-in',
                                     token_url: '/auth/oauth/token'))
  end

  # :nocov:
  def self.decode_roles(token)
    public_key = Base64.urlsafe_decode64(
      Rails.configuration.nomis_oauth_public_key
    )

    decoded_token = JWT.decode(
      token,
      OpenSSL::PKey::RSA.new(public_key),
      true,
      algorithm: 'RS256'
    )

    decoded_token.first.fetch('authorities', [])
  end

  # :nocov:

  def active_caseload
    caseload = @user_details.active_case_load_id
    return caseload if caseload.present?

    caseload_codes.first
  end

  def user_details
    @user_details = HmppsApi::PrisonApi::UserApi.user_details(username)
    @user_details.nomis_caseloads = HmppsApi::PrisonApi::UserApi.user_caseloads(
      @user_details.staff_id)
    @user_details
  end

  def caseload_codes
    @caseload_codes = @user_details.nomis_caseloads.map do |codes|
      codes['caseLoadId']
    end
  end

  # :nocov:
  def username
    access_token.params.fetch('user_name')
  end
end

