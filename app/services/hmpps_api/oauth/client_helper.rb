# frozen_string_literal: true

require 'base64'

#:nocov:
module HmppsApi
  module Oauth
    module ClientHelper
      def authorisation
        'Basic ' + Base64.urlsafe_encode64(
          "#{Rails.configuration.nomis_oauth_client_id}:#{Rails.configuration.nomis_oauth_client_secret}"
        )
      end
    end
  end
end
#:nocov:
