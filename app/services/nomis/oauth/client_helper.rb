# frozen_string_literal: true

require 'base64'

#:nocov:
module Nomis
  module Oauth
    module ClientHelper
      # rubocop:disable Metrics/LineLength
      def authorisation
        'Basic ' + Base64.urlsafe_encode64(
          "#{Rails.configuration.nomis_oauth_client_id}:#{Rails.configuration.nomis_oauth_client_secret}"
        )
      end
      # rubocop:enable Metrics/LineLength
    end
  end
end
#:nocov:
