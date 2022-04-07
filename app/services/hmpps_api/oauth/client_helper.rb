# frozen_string_literal: true

require 'base64'

# :nocov:
module HmppsApi
  module Oauth
    module  ClientHelper
      def api_authorisation
        "Basic #{Base64.urlsafe_encode64(
          "#{Rails.configuration.hmpps_api_client_id}:#{Rails.configuration.hmpps_api_client_secret}"
        )}"
      end

      def user_login_authorisation
        "Basic #{Base64.urlsafe_encode64(
          "#{Rails.configuration.hmpps_oauth_client_id}:#{Rails.configuration.hmpps_oauth_client_secret}"
        )}"
      end
    end
  end
end
# :nocov:
