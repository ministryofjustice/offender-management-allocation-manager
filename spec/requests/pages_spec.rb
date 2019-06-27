require 'rails_helper'

describe 'POST /contact', type: :request do
  it 'submits a form with contact information' do
    post '/contact', params: { more_detail: "Message Body" }

    expect(response.status).to eq(302)
  end

  it 'submits an empty form' do
    post '/contact', params: { more_detail: "" }

    expect(response.status).to eq(200)
  end
end
