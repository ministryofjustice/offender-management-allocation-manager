module Nomis
  module Oauth
    class Token
      attr_reader :type, :expiry, :access_token, :expires_at

      def initialize(payload)
        @type = payload['token_type']
        @expiry = payload['expires_in']
        @access_token = payload['access_token']
      end
    end
  end
end
