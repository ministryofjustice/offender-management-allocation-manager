require 'rails_helper'

describe 'pages', type: :request do
  describe 'POST /help' do
    before do
      allow(ZendeskTicketsJob).to receive(:perform_later).and_return(true)
    end

    it 'submits a form with contact information' do
      post '/contact_us', params: { "email_address" => "kath@example.com", "name" => "Kath", "job_type" => "SPO", "prison" => "Leeds", "message" => "This is a query" }

      expect(response.status).to eq(302)
    end

    it 'submits an empty form' do
      post '/contact_us', params: { message: "" }

      expect(response.status).to eq(200)
    end
  end

  describe 'GET /whats_new' do
    it 'returns the whats new page' do
      get '/whats-new'
      expect(response).to render_template(:whats_new)
    end
  end
end
