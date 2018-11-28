require 'jwt'
require 'rails_helper'

describe Nomis::Oauth::Token, model: true do
  it 'can confirm if it is not expired' do
    payload = {
      'internal_user': false,
      'scope': %w[read write],
      'exp': 4.hours.from_now.to_i,
      'client_id': 'offender-management-allocation-manager'
    }

    rsa_private = OpenSSL::PKey::RSA.generate 2048
    rsa_public = rsa_private.public_key

    Rails.configuration.nomis_oauth_public_key = rsa_public

    encrypted_token = JWT.encode payload, rsa_private, 'RS256'
    token = Nomis::Oauth::Token.new(encrypted_token)

    expect(token).not_to be_expired
  end

  it 'can confirm if it is expired' do
    expired_payload = {
      'internal_user': false,
      'scope': %w[read write],
      'exp': 4.hours.ago.to_i,
      'client_id': 'offender-management-allocation-manager'
    }

    rsa_private = OpenSSL::PKey::RSA.generate 2048
    rsa_public = rsa_private.public_key

    Rails.configuration.nomis_oauth_public_key = rsa_public

    encrypted_token = JWT.encode expired_payload, rsa_private, 'RS256'
    token = Nomis::Oauth::Token.new(encrypted_token)

    expect(token).to be_expired
  end
end
