# frozen_string_literal: true

require 'swagger_helper'

describe 'SAR template API' do
  let(:Authorization) { 'Bearer TEST_TOKEN' }
  let(:template_path) { SubjectAccessRequestTemplateService.template_path }

  path '/subject-access-request/template' do
    get 'Retrieves the SAR Mustache template for this service' do
      tags 'Subject Access Request'
      description "* The role ROLE_SAR_DATA_ACCESS is required
* Returns the plain-text Mustache template configured for the service"

      response '401', 'Request is not authorised' do
        security [{ Bearer: [] }]
        metadata[:response][:schema] = { '$ref' => '#/components/schemas/SarError' }
        metadata[:response][:content] = {
          'application/json' => {
            schema: { '$ref' => '#/components/schemas/SarError' }
          }
        }

        let(:Authorization) { nil }

        run_test!
      end

      response '403', 'Invalid token role' do
        security [{ Bearer: [] }]
        metadata[:response][:schema] = { '$ref' => '#/components/schemas/SarError' }
        metadata[:response][:content] = {
          'application/json' => {
            schema: { '$ref' => '#/components/schemas/SarError' }
          }
        }

        before do
          stub_decoded_token(authorities: %w[ROLE_FOOBAR])
        end

        run_test!
      end

      response '200', 'Template returned for SAR users' do
        security [{ Bearer: [] }]
        metadata[:response][:schema] = { type: :string }
        metadata[:response][:content] = {
          'text/plain' => {
            schema: { type: :string }
          }
        }

        before do
          stub_decoded_token(authorities: %w[ROLE_SAR_DATA_ACCESS])
        end

        run_test! do |response|
          expect(response.media_type).to eq('text/plain')
          expect(response.body).to eq(File.read(template_path, encoding: 'UTF-8'))
        end
      end
    end
  end
end
