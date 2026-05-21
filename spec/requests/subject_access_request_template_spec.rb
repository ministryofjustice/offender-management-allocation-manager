# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Subject access request template' do
  let(:endpoint) { '/subject-access-request/template' }
  let(:token) { 'Bearer TEST_TOKEN' }
  let(:headers) { { 'AUTHORIZATION' => token } }
  let(:template_path) { SubjectAccessRequestTemplateService.template_path }

  describe 'GET /subject-access-request/template' do
    context 'when the client has the ROLE_SAR_DATA_ACCESS role' do
      before do
        stub_decoded_token(authorities: %w[ROLE_SAR_DATA_ACCESS])
        get endpoint, headers: headers
      end

      it 'returns status OK' do
        expect(response).to have_http_status(:ok)
      end

      it 'returns the template body as plain text' do
        expect(response.media_type).to eq('text/plain')
        expect(response.body).to eq(File.read(template_path, encoding: 'UTF-8'))
      end
    end

    context 'when the client lacks an allowed role' do
      before do
        stub_decoded_token(authorities: %w[ROLE_WHATEVER])
        get endpoint, headers: headers
      end

      it 'returns a SAR forbidden response' do
        expect(response).to have_http_status(:forbidden)
        expect(JSON.parse(response.body)).to eq(
          'developerMessage' => 'Invalid token role',
          'errorCode' => 5,
          'status' => 403,
          'userMessage' => 'Invalid token role'
        )
      end
    end

    context 'when the client is unauthenticated' do
      before do
        get endpoint
      end

      it 'returns a SAR unauthorized response' do
        expect(response).to have_http_status(:unauthorized)
        expect(JSON.parse(response.body)).to eq(
          'developerMessage' => 'Valid authorisation token required',
          'errorCode' => 1,
          'status' => 401,
          'userMessage' => 'Valid authorisation token required'
        )
      end
    end
  end
end
