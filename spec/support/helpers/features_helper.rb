module FeaturesHelper
  # Signs in a user which historically has always been an SPO. For backwards
  # compatability this continues to mock sso for an SPO, but we should move
  # in future to one of the explicit signin_*_user methods below.
  def signin_user(name = 'MOIC_POM')
    signin_spo_user(name)
  end

  def signin_spo_user(name = 'MOIC_POM')
    mock_sso_response(name, ['ROLE_ALLOC_MGR'])
  end

  def signin_global_admin_user
    mock_sso_response('MOIC_POM', ['ROLE_ALLOC_MGR'], PrisonService.prison_codes)
  end

  def signin_pom_user(name = 'MOIC_POM')
    mock_sso_response(name, ['ROLE_ALLOC_CASE_MGR'])
  end

  def mock_sso_response(name, roles, caseloads = %w[LEI RSI])
    hmpps_sso_response = {
      'info' => double('user_info', username: name, active_caseload: 'LEI', caseloads: caseloads, roles: roles),
      'credentials' => double('credentials', expires_at: Time.zone.local(2030, 1, 1).to_i,
                                             'authorities': roles)
    }

    OmniAuth.config.add_mock(:hmpps_sso, hmpps_sso_response)
  end
end
