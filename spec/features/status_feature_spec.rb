require 'rails_helper'

RSpec.feature 'fetch status' do
  it 'returns a status message' do
    stub_request(
      :get,
      'http://localhost:8000/status'
    ).to_return(
      status: 200,
      body: {
        'status' => 'ok',
        'postgresVersion' => 'PostgreSQL 10.3'
      }.to_json
    )

    stub_request(
      :post,
      "#{Rails.configuration.nomis_oauth_url}/auth/oauth/token?grant_type=client_credentials"
    ).to_return(
      status: 200,
      body: {
        'access_token' => generate_jwt_token,
        'expires_in' => 4.hours.from_now.to_i }.to_json
    )

    visit '/'

    expect(page).to have_css('.status', text: 'ok')
    expect(page).to have_css('.postgres_version', text: 'PostgreSQL 10.3')
  end
end
