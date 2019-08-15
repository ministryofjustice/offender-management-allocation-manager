# frozen_string_literal: true

module Nomis
  module Keyworker
    class KeyworkerApi
      def self.get_keyworker(location, offender_no)
        route = "/key-worker/#{location}/offender/#{offender_no}"
        h = Digest::SHA256.hexdigest(offender_no.to_s)
        key = "keyworker_details_for_offender_#{h}"

        response = Rails.cache.fetch(key, expires_in: Rails.configuration.cache_expiry) {
          client.get(route)
        }
        ApiDeserialiser.new.deserialise(Nomis::Models::KeyworkerDetails, response)
      rescue Nomis::Client::APIError
        Nomis::Models::NullKeyworker.new
      end

      def self.client
        host = Rails.configuration.keyworker_api_host
        Nomis::Client.new(host)
      end
    end
  end
end
