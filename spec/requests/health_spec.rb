require 'rails_helper'

describe 'GET /health', type: :request do
  it 'returns a plain text status' do
    get('/health')

    expect(response.body).to eq('Everything is fine.')
  end
end
