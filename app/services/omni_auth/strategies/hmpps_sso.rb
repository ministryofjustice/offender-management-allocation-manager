# frozen_string_literal: true

require 'omniauth-oauth2'

module OmniAuth
  module Strategies
    class HmppsSso < OmniAuth::Strategies::OAuth2
      include HmppsApi::Oauth::ClientHelper

      option :name, 'hmpps_sso'

      info do
        {
          username: user_details.username,
          staff_id: user_details.staff_id,
          active_caseload: active_caseload.upcase,
          caseloads: caseload_codes,
          roles: decode_roles
        }
      end

      # :nocov:
      def build_access_token
        options.token_params[:headers] = { 'Authorization' => user_login_authorisation }
        super
      end
      # :nocov:

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

      # :nocov:
      def decode_roles
        decoded_token = JwksDecoder.decode_token(access_token.token)
        decoded_token.first.fetch('authorities', [])
      end
      # :nocov:

      def active_caseload
        caseload = @user_details.active_case_load_id
        return caseload if caseload.present?

        caseload_codes.first
      end

      def user_details
        @user_details = HmppsApi::NomisUserRolesApi.staff_details(staff_id, cache: false)
      end

      def caseload_codes
        @caseload_codes = @user_details.caseloads
      end

      # :nocov:
      def username
        access_token.params.fetch('user_name')
      end

      def staff_id
        access_token.params.fetch('user_id')
      end
      # :nocov:
    end
  end
end
