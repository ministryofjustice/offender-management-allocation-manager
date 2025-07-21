# frozen_string_literal: true

module AuthHelper
  ACCESS_TOKEN = Struct.new(:access_token).new('an-access-token')
  USER_ACCESS_TOKEN = 'fake-user-access-token'

  def auth_header
    oauth_client = HmppsApi::Oauth::Client.new(Rails.configuration.nomis_oauth_host)
    route = "/auth/oauth/token?grant_type=client_credentials"
    response = oauth_client.post(route)
    access_token = response.fetch("access_token")
    "Bearer #{access_token}"
  end

  def stub_auth_token
    allow(HmppsApi::Oauth::TokenService).to receive(:valid_token).and_return(ACCESS_TOKEN)

    stub_request(:get, "#{ApiHelper::AUTH_HOST}/auth/.well-known/jwks.json")
      .to_return(body: {
        'keys' => [{ 'kty' => 'RSA', 'e' => 'AQAB', 'use' => 'unused', 'kid' => 'xxxx1', 'alg' => 'ALGO_UNUSED', 'n' => 'nnnnnnnn1' }]
      }.to_json)

    stub_request(:post, "#{ApiHelper::AUTH_HOST}/auth/oauth/token?grant_type=client_credentials")
      .to_return(body: {
        "access_token": ACCESS_TOKEN.access_token,
        "token_type": "bearer",
        "expires_in": 1199,
        "scope": "readwrite"
      }.to_json)
  end

  def stub_sso_data(prison, username: 'user', staff_id: 754_732, roles: [SsoIdentity::SPO_ROLE], email: '754732@example.com')
    allow(HmppsApi::Oauth::TokenService).to receive(:valid_token).and_return(ACCESS_TOKEN)

    stub_pom(
      build(:pom, staffId: staff_id, firstName: 'MOIC', lastName: 'POM', primaryEmail: email)
    )

    if defined?(session)
      session[:sso_data] = {
        'expiry' => Time.zone.now + 1.day,
        'roles' => roles,
        'caseloads' => [prison],
        'username' => username,
        'staff_id' => staff_id,
        'token' => USER_ACCESS_TOKEN,
      }
    end
  end

  # Stub out authentication and authorization at a high level - does not go near the API calls, simply stubs out
  # the controller helpers that authenticate and authorize.
  # @param prison A Prison model or mock set to @prison - if a mock, must have valid #code attribute
  # @param staff_member If StaffMember model/stub is given, authorize to that; otherwise create a new anonymous stub

  # TODO: this amount of stubbing to get the tests to run really tells us that our controller plumbing is not very
  #  well designed. We need to find ways to tidy it up, one strand at a time.

  def stub_high_level_staff_member_auth(prison:, staff_member: nil)
    staff_member ||= instance_double(StaffMember, staff_id: Random.rand(100))
    allow(controller).to receive_messages(authenticate_user: nil,
                                          check_prison_access: nil,
                                          load_staff_member: nil,
                                          service_notifications: nil,
                                          load_roles: nil,
                                          active_prison_id: prison.code)
    controller.instance_variable_set(:@current_user, staff_member)
    controller.instance_variable_set(:@prison, prison)
  end

  def stub_high_level_pom_auth(prison:, staff_member: nil)
    staff_member ||= instance_double(StaffMember, :pom_staff_member, staff_id: Random.rand(100))
    stub_high_level_staff_member_auth(prison: prison, staff_member: staff_member)
    allow(controller).to receive_messages(ensure_pom: nil,
                                          current_user_is_pom?: true)
  end
end
