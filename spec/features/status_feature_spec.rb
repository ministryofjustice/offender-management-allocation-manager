require 'rails_helper'

feature 'get status' do
  it 'returns a status message', vcr: { cassette_name: :get_status_feature } do
    stub_request(
      :get,
      "#{Rails.configuration.allocation_api_host}/status"
    ).to_return(
      status: 200,
      body: {
        'status' => 'ok',
        'postgresVersion' => 'PostgreSQL 10.3'
      }.to_json
    )

    stub_request(
      :post,
      "#{Rails.configuration.nomis_oauth_host}/auth/oauth/token?grant_type=client_credentials"
    ).to_return(
      status: 200,
      body: {
        'access_token' => generate_jwt_token,
        'expires_in' => four_hours_from_now }.to_json
    )

    visit '/'

    expect(page).to have_css('.status', text: 'ok')
    expect(page).to have_css('.postgres_version', text: 'PostgreSQL 10.3')
  end
end
