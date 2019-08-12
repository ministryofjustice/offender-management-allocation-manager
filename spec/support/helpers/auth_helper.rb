module AuthHelper
  T3 = 'https://gateway.t3.nomis-api.hmpps.dsd.io'
  ACCESS_TOKEN = 'an access token'

  def stub_auth_token
    allow(Nomis::Oauth::TokenService).to receive(:valid_token).and_return(OpenStruct.new(access_token: ACCESS_TOKEN))

    stub_request(:post, "#{T3}/auth/oauth/token?grant_type=client_credentials").
      to_return(status: 200, body: {
        "access_token": ACCESS_TOKEN,
        "token_type": "bearer",
        "expires_in": 1199,
        "scope": "readwrite"
      }.to_json, headers: {})
  end
end
