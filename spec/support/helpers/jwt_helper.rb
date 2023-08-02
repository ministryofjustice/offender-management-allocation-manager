require 'base64'

module JWTHelper
  def generate_jwt_token(options = {})
    payload = {
      'internal_user': false,
      'scope': %w[read write],
      'exp': 4.hours.from_now.to_i,
      'client_id': 'offender-management-allocation-manager'
    }.merge(options)

    rsa_private = OpenSSL::PKey::RSA.generate 2048
    allow(JwksKey).to receive(:openssl_public_key).and_return(rsa_private.public_key)

    JWT.encode payload, rsa_private, 'RS256'
  end
end
