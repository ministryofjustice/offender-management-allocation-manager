require 'base64'

#:nocov:
module Nomis::Oauth
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
#:nocov:
