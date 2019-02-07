require 'rails_helper'

describe 'GET /status', type: :request do
  let(:authorization) { { Authorization: "Bearer #{generate_jwt_token}" } }

  it 'get the Postgres version' do
    get '/status', headers: authorization

    json = JSON.parse(response.body)

    expect(json['status']).to eq('ok')
    expect(json['postgresVersion']).to match(/PostgreSQL/)
  end
end
