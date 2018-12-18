module FeaturesHelper
  def signin_user(name = 'Fred')
    hmpps_sso_response = {
      'info' => {
        'username' => name,
        'caseload' => 'LEI'
      }
    }

    OmniAuth.config.add_mock(:hmpps_sso, hmpps_sso_response)
  end
end
