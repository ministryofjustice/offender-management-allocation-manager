require 'rails_helper'

describe 'POST /help', type: :request do
  before do
    allow(ZendeskTicketsJob).to receive(:perform_later).and_return(true)
  end

  it 'submits a form with contact information' do
    post '/help', params: { "email_address" => "kath@example.com", "name" => "Kath", "job_type" => "SPO", "prison" => "Leeds", "message" => "This is a query" }

    expect(response.status).to eq(302)
  end

  it 'submits an empty form' do
    post '/help', params: { message: "" }

    expect(response.status).to eq(200)
  end
end
