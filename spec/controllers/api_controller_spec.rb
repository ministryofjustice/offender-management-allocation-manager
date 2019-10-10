require 'rails_helper'

RSpec.describe ApiController, type: :controller do
  let(:rsa_private) { OpenSSL::PKey::RSA.generate 2048 }
  let(:rsa_public) { Base64.strict_encode64(rsa_private.public_key.to_s) }
  let(:error_message) { {'status' => 'error', 'message' => 'Invalid token'} }
  let(:ok_message) { { 'status' => 'ok' } }

  before do
    allow(Rails.configuration).to receive(:nomis_oauth_public_key).and_return(rsa_public)
  end

  it 'blocks access for missing tokens' do
    get :index

    expect(response).to have_http_status(200)
    expect(JSON.parse(response.body)).to eq(error_message)
  end

  it 'blocks non-bearer tokens' do
    request.headers['AUTHORIZATION'] = "wombles"

    get :index

    expect(response).to have_http_status(200)
    expect(JSON.parse(response.body)).to eq(error_message)
  end

  it 'blocks bearer tokens that can not be decrypted' do
    request.headers['AUTHORIZATION'] = "Bearer wombles"

    get :index

    expect(response).to have_http_status(200)
    expect(JSON.parse(response.body)).to eq(error_message)
  end

  it 'blocks bearer tokens without an expiry date' do
    payload = {
      user_name: 'hello'
    }

    request_header(payload)
    get :index

    expect(response).to have_http_status(200)
    expect(JSON.parse(response.body)).to eq(error_message)
  end

  it 'blocks expired bearer tokens' do
    payload = {
      user_name: 'hello',
      exp: 4.hours.ago.to_i
    }

    request_header(payload)
    get :index

    expect(response).to have_http_status(200)
    expect(JSON.parse(response.body)).to eq(error_message)
  end

  it 'blocks tokens without a scope' do
    payload = {
      user_name: 'hello',
      exp: 4.hours.from_now.to_i
    }

    request_header(payload)
    get :index

    expect(response).to have_http_status(200)
    expect(JSON.parse(response.body)).to eq(error_message)
  end

  it 'blocks tokens that do not have a read scope' do
    payload = {
      user_name: 'hello',
      scope: ['write'],
      exp: 4.hours.from_now.to_i
    }

    request_header(payload)
    get :index

    expect(response).to have_http_status(200)
    expect(JSON.parse(response.body)).to eq(error_message)
  end

  it 'accepts bearer tokens that are not expired with a read scope' do
    payload = {
      user_name: 'hello',
      scope: ['read'],
      exp: 4.hours.from_now.to_i
    }

    request_header(payload)
    get :index

    expect(response).to have_http_status(200)
    expect(JSON.parse(response.body)).to eq(ok_message)
  end

  def encode_payload(payload)
    JWT.encode(payload, OpenSSL::PKey::RSA.new(rsa_private), 'RS256')
  end

  def request_header(payload)
    token = encode_payload(payload)
    request.headers['AUTHORIZATION'] = "Bearer #{token}"
  end
end
