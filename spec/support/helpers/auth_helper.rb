# frozen_string_literal: true

module AuthHelper
  T3 = 'https://gateway.t3.nomis-api.hmpps.dsd.io'
  ACCESS_TOKEN = Struct.new(:access_token).new('an-access-token')

  def stub_auth_token
    allow(Nomis::Oauth::TokenService).to receive(:valid_token).and_return(ACCESS_TOKEN)

    stub_request(:post, "#{T3}/auth/oauth/token?grant_type=client_credentials").
      to_return(body: {
        "access_token": ACCESS_TOKEN.access_token,
        "token_type": "bearer",
        "expires_in": 1199,
        "scope": "readwrite"
      }.to_json)
  end

  def stub_sso_data(prison, username = 'user', role = 'ROLE_ALLOC_MGR')
    allow(Nomis::Oauth::TokenService).to receive(:valid_token).and_return(ACCESS_TOKEN)
    session[:sso_data] = { 'expiry' => Time.zone.now + 1.day,
                           'roles' => [role],
                           'caseloads' => [prison],
                           'username' => username }
    stub_request(:get, "#{T3}/elite2api/api/users/#{username}").
        to_return(status: 200, body: { 'staffId': 754_732 }.to_json)
    stub_request(:get, "#{T3}/elite2api/api/staff/754732/emails").
        to_return(status: 200, body: [].to_json)
  end
end
