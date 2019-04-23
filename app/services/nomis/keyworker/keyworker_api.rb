# frozen_string_literal: true

module Nomis
  module Keyworker
    class KeyworkerApi
      def self.get_keyworker(location, offender_no)
        route = "/key-worker/#{location}/offender/#{offender_no}"
        h = Digest::SHA256.hexdigest(offender_no.to_s)
        key = "keyworker_details_for_offender_#{h}"

        response = Rails.cache.fetch(key, expires_in: 10.minutes) {
          client.get(route)
        }
        ApiDeserialiser.new.deserialise(Nomis::Models::KeyworkerDetails, response)
      rescue Nomis::Client::APIError => e
        AllocationManager::ExceptionHandler.capture_exception(e)
        Nomis::Models::NullKeyworker.new
      end

      def self.client
        host = Rails.configuration.keyworker_api_host
        Nomis::Client.new(host)
      end
    end
  end
end
