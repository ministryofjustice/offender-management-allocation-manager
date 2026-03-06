# frozen_string_literal: true

module HmppsApi
  class ResponseCache
    CACHE_EXPIRY = Rails.configuration.cache_expiry
    CACHE_VERSION = 2

    CachedResponse = Struct.new(:status, :body, keyword_init: true) do
      def to_cache_payload
        { 'status' => status, 'body' => body }
      end

      def self.from_cache_payload(payload)
        new(status: payload.fetch('status'), body: payload.fetch('body'))
      end
    end

    def initialize(root)
      @root = root
    end

    def read(method:, route:, queryparams: {}, extra_headers: {}, body: nil)
      cached_payload = Rails.cache.read(
        cache_key(method:, route:, queryparams:, extra_headers:, body:)
      )
      return nil unless cached_payload

      deserialize_from_cache(cached_payload)
    end

    def write(method:, route:, queryparams: {}, extra_headers: {}, body: nil, response: nil)
      key = cache_key(method:, route:, queryparams:, extra_headers:, body:)
      Rails.cache.write(key, serialize_for_cache(response), expires_in: CACHE_EXPIRY)
    end

    def expire(method:, route:, queryparams: {}, extra_headers: {}, body: nil)
      key = cache_key(method:, route:, queryparams:, extra_headers:, body:)
      Rails.cache.delete(key)
    end

  private

    def cache_key(method:, route:, queryparams: {}, extra_headers: {}, body: nil)
      # An array of everything that makes this request unique
      request_parameters = [@root, method, route, queryparams, extra_headers, body]

      # Create a SHA256 hash which uniquely identifies this request
      fingerprint = Digest::SHA256.hexdigest(request_parameters.to_json)

      "hmpps_api_request_v#{CACHE_VERSION}_#{fingerprint}"
    end

    def serialize_for_cache(response)
      CachedResponse.new(status: response.status, body: response.body).to_cache_payload
    end

    def deserialize_from_cache(payload)
      CachedResponse.from_cache_payload(payload)
    end
  end
end
