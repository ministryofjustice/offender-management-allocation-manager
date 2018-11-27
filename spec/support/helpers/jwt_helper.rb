module JWTHelper
  def generate_jwt_token(options = {})
    payload = {
      'internal_user': false,
      'scope': %w[read write],
      'exp': four_hours_from_now,
      'client_id': 'offender-management-allocation-manager'
    }.merge(options)

    rsa_private = OpenSSL::PKey::RSA.generate 2048
    rsa_public = rsa_private.public_key
    Rails.configuration.nomis_oauth_public_key = rsa_public

    JWT.encode payload, rsa_private, 'RS256'
  end

  def four_hours_from_now
    Time.new.to_i + 3600
  end

  def four_hours_ago
    Time.new.to_i - 3600
  end
end
