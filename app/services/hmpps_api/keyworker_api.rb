# frozen_string_literal: true

module HmppsApi
  class KeyworkerApi
    def self.get_keyworker(location, offender_no)
      route = "/key-worker/#{location}/offender/#{offender_no}"
      h = Digest::SHA256.hexdigest(offender_no.to_s)
      key = "keyworker_details_for_offender_#{h}"

      response = Rails.cache.fetch(key, expires_in: Rails.configuration.cache_expiry) {
        client.get(route)
      }
      ApiDeserialiser.new.deserialise(HmppsApi::KeyworkerDetails, response)
    rescue HmppsApi::Client::APIError
      HmppsApi::NullKeyworker.new
    end

    def self.client
      host = Rails.configuration.keyworker_api_host
      HmppsApi::Client.new(host, false)
    end
  end
end
