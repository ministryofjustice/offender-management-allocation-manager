module FeaturesHelper
  def signin_user(name = 'Fred')
    hmpps_sso_response = {
      'info' => double('user_info', username: name, active_caseload: 'LEI', caseloads: %w[LEI RSI], roles: %w[ROLE_ALLOC_MGR]),
      'credentials' => double('credentials', expires_at: Time.zone.local(2030, 1, 1).to_i,
                                             'authorities': ['ROLE_ALLOC_MGR'])
    }

    OmniAuth.config.add_mock(:hmpps_sso, hmpps_sso_response)
  end
end
