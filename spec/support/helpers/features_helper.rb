# frozen_string_literal: true

module FeaturesHelper
  def signin_spo_user(name = 'MOIC_POM')
    mock_sso_response(name, ['ROLE_ALLOC_MGR'])
  end

  def signin_global_admin_user
    mock_sso_response('MOIC_POM', ['ROLE_ALLOC_MGR'], PrisonService.prison_codes)
  end

  def signin_pom_user
    mock_sso_response('MOIC_POM', ['ROLE_ALLOC_CASE_MGR'])
  end

  def mock_sso_response(username, roles, caseloads = %w[LEI RSI])
    hmpps_sso_response = {
      'info' => double('user_info', username: username, active_caseload: 'LEI', caseloads: caseloads, roles: roles),
      'credentials' => double('credentials', expires_at: Time.zone.local(2030, 1, 1).to_i,
                                             'authorities': roles)
    }

    OmniAuth.config.add_mock(:hmpps_sso, hmpps_sso_response)
  end

  def stub_user(username: 'MOIC_POM', staff_id:)
    stub_request(:get, "#{ApiHelper::T3}/users/#{username}").
      to_return(body: { 'staffId': staff_id }.to_json)
    stub_request(:get, "#{ApiHelper::T3}/staff/#{staff_id}/emails").
      to_return(body: [].to_json)
  end
end
