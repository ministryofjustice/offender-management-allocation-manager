require 'omniauth-oauth2'

module OmniAuth
  module Strategies
    class HmppsSso < OmniAuth::Strategies::OAuth2
      include Nomis::Oauth::ClientHelper

      option :name, 'hmpps_sso'

      info do
        {
          username: staff_details.username,
          caseload: staff_details.active_case_load_id
        }
      end

      #:nocov:
      def build_access_token
        options.token_params[:headers] = { 'Authorization' => authorisation }
        super
      end
      #:nocov:

      # Without this login with sso breaks.
      # This issued was first identified in the Prison Visits Booking service. See
      # https://github.com/ministryofjustice/prison-visits-2/commit/1aaf9fba367b084e1127e3269efbf8e883f3c45b
      # Issue has still not been resolved by the library owners.
      # Fix implemented as suggested here:
      # https://github.com/intridea/omniauth-oauth2/commit/26152673224aca5c3e918bcc83075dbb0659717f#commitcomment-19809835
      # Other link about the issue: https://github.com/intridea/omniauth-oauth2/issues/81
      # omniauth-oauth2 after version 1.3.1 changed the way that the callback
      # url gets generated. This new version doesn't match the redirect uri as set in
      # SSO so login breaks.
      # The issue seems quite common among multiple SSO providers like Google,
      # Facebook, Dropbox, etc

      def callback_url
        full_host + script_name + callback_path
      end

    private

      def staff_details
        @staff_details ||= Nomis::Elite2::Api.fetch_nomis_user_details(username).data
      end

      #:nocov:
      def username
        access_token.params.fetch('user_name')
      end
    end
  end
end
