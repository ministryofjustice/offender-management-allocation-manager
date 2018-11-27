require 'jwt'
require 'rails_helper'

describe Nomis::Oauth::Token, model: true do
  payload = {
        'internal_user': false,
        'scope': %w[read write],
        'exp': Time.new.to_i + 4 * 3600,
        'client_id': 'offender-management-allocation-manager'
      }

  expired_payload = {
    'internal_user': false,
    'scope': %w[read write],
    'exp': Time.new.to_i - 3600,
    'client_id': 'offender-management-allocation-manager'
  }

  it '' do
    rsa_private = OpenSSL::PKey::RSA.generate 2048
    rsa_public = rsa_private.public_key

    Rails.configuration.nomis_oauth_public_key = rsa_public

    encrypted_token = JWT.encode payload, rsa_private, 'RS256'
    token = Nomis::Oauth::Token.new(encrypted_token)

    expect(token).not_to be_expired
  end

  it '' do
    rsa_private = OpenSSL::PKey::RSA.generate 2048
    rsa_public = rsa_private.public_key

    Rails.configuration.nomis_oauth_public_key = rsa_public

    encrypted_token = JWT.encode expired_payload, rsa_private, 'RS256'
    token = Nomis::Oauth::Token.new(encrypted_token)

    expect(token).to be_expired
  end

end
