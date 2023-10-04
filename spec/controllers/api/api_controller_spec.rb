require 'rails_helper'

RSpec.describe Api::ApiController, type: :controller do
  let(:ok_message) { { 'status' => 'ok' } }

  it 'blocks access for missing tokens' do
    get :index

    expect(response).to have_http_status(:unauthorized)
    expect(JSON.parse(response.body)['status']).to eq('error')
  end

  it 'blocks non-bearer tokens' do
    request.headers['AUTHORIZATION'] = "wombles"

    get :index

    expect(response).to have_http_status(:unauthorized)
    expect(JSON.parse(response.body)['status']).to eq('error')
  end

  it 'blocks bearer tokens that can not be decrypted' do
    request.headers['AUTHORIZATION'] = "Bearer wombles"

    get :index

    expect(response).to have_http_status(:unauthorized)
    expect(JSON.parse(response.body)['status']).to eq('error')
  end

  it 'blocks bearer tokens without an expiry date' do
    payload = {
      user_name: 'hello',
      exp: nil,
    }

    request_header(payload)
    get :index

    expect(response).to have_http_status(:unauthorized)
    expect(JSON.parse(response.body)['status']).to eq('error')
  end

  it 'blocks expired bearer tokens' do
    payload = {
      user_name: 'hello',
      exp: 4.hours.ago.to_i
    }

    request_header(payload)
    get :index

    expect(response).to have_http_status(:unauthorized)
    expect(JSON.parse(response.body)['status']).to eq('error')
  end

  it 'blocks tokens without a scope' do
    payload = {
      user_name: 'hello',
      exp: 4.hours.from_now.to_i
    }

    request_header(payload)
    get :index

    expect(response).to have_http_status(:unauthorized)
    expect(JSON.parse(response.body)['status']).to eq('error')
  end

  it 'blocks tokens that do not have a read scope' do
    payload = {
      user_name: 'hello',
      scope: ['write'],
      exp: 4.hours.from_now.to_i
    }

    request_header(payload)
    get :index

    expect(response).to have_http_status(:unauthorized)
    expect(JSON.parse(response.body)['status']).to eq('error')
  end

  it 'accepts bearer tokens that are not expired with a read scope' do
    allow_any_instance_of(HmppsApi::Oauth::Token).to receive(:valid_token_with_scope?).and_return(true)

    request_header
    get :index

    expect(response).to have_http_status(:ok)
    expect(JSON.parse(response.body)).to eq(ok_message)
  end

  def request_header(payload = {})
    allow(JwksDecoder).to receive(:decode_token).and_return(
      [
        {
          scope: %w[read write],
          exp: 4.hours.from_now.to_i,
        }.merge(payload)
      ]
    )
    request.headers['AUTHORIZATION'] = "Bearer xxxxxxx"
  end
end
