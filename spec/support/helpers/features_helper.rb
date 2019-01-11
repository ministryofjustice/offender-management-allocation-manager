module FeaturesHelper
  def signin_user(name = 'Fred')
    hmpps_sso_response = {
      'info' => double('user_info', username: name, caseload: 'LEI'),
      'credentials' => double('credentials', expires_at: Time.zone.local(2030, 1, 1).to_i)
    }

    p '---------------------------------------------'
    p 'Mocking AUTH'
    p '---------------------------------------------'

    OmniAuth.config.add_mock(:hmpps_sso, hmpps_sso_response)
  end
end
