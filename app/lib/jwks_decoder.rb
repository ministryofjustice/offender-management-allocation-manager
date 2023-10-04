class JwksDecoder
  class << self
    def jwks_keys
      @jwks_keys ||= HmppsApi::Oauth::Api.fetch_jwks_keys
    end

    def clear_jwks_keys_cache!
      @jwks_key_data = nil
    end

    def decode_token(encoded_token)
      jwks = JWT::JWK::Set.new(HmppsApi::Oauth::Api.fetch_jwks_keys).filter { |key| key[:use] == 'sig' }
      algorithms = jwks.map { |key| key['alg'] }.compact.uniq
      JWT.decode(
        encoded_token,
        nil,
        true,
        algorithm: algorithms,
        jwks: jwks,
      )
    end
  end
end
