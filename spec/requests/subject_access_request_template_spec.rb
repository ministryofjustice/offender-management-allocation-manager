# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'Subject access request template' do
  let(:endpoint) { '/subject-access-request/template' }
  let(:token) { 'Bearer TEST_TOKEN' }
  let(:headers) { { 'AUTHORIZATION' => token } }

  describe 'GET /subject-access-request/template' do
    SubjectAccessRequestReport::DATA_SERVICES.each_key do |revision|
      context "when #{revision} is configured" do
        before do
          allow(Rails.application.config.x).to receive(:sar_report_version).and_return(revision)
          stub_decoded_token(authorities: %w[ROLE_SAR_DATA_ACCESS])
          get endpoint, headers: headers
        end

        it 'returns the configured template as plain text' do
          expect(response).to have_http_status(:ok)
          expect(response.media_type).to eq('text/plain')
          expect(response.body).to eq(Rails.root.join("config/templates/#{revision}_sar_template.mustache").read(encoding: 'UTF-8'))
        end
      end
    end

    it 'includes the review fields in the v1-r2 template' do
      template = Rails.root.join('config/templates/v1-r2_sar_template.mustache').read(encoding: 'UTF-8')
      expect(template).to include('{{#if primaryPomReviewedAt}}Yes{{else}}No{{/if}}',
                                  '{{ optionalValue (formatDate primaryPomReviewedAt) }}',
                                  '{{ optionalValue reviewedRecommendedPomType }}')
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
