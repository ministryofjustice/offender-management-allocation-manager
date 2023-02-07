# frozen_string_literal: true

module HmppsApi
  class KeyworkerApi
    def self.get_keyworker(location, offender_no)
      route = "/key-worker/#{location}/offender/#{offender_no}"
      response = client.get(route)
      ApiDeserialiser.new.deserialise(HmppsApi::KeyworkerDetails, response)
    rescue Faraday::ResourceNotFound # 404 Not Found error
      HmppsApi::NullKeyworker.new
    rescue Faraday::Error => e
      Rails.logger.error(
        "nomis_offender_id=#{offender_no},event=keyworker_api_error|#{e.inspect},#{e.backtrace.join(',')}")
      HmppsApi::NullKeyworker.new
    end

    def self.client
      host = Rails.configuration.keyworker_api_host
      HmppsApi::Client.new(host)
    end
  end
end
