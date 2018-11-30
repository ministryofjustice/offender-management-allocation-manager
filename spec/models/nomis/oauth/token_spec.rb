require 'rails_helper'

describe Nomis::Oauth::Token, model: true do
  it 'can confirm if it is not expired' do
    access_token = generate_jwt_token
    token = Nomis::Oauth::Token.new(access_token)

    expect(token).not_to be_expired
  end

  it 'can confirm if it is expired' do
    access_token = generate_jwt_token('exp' => 4.hours.ago.to_i)
    token = Nomis::Oauth::Token.new(access_token)

    expect(token).to be_expired
  end
end
