# frozen_string_literal: true

require 'swagger_helper'

describe 'SAR template API' do
  let(:Authorization) { 'Bearer TEST_TOKEN' }
  let(:template_path) { SubjectAccessRequestTemplateService.template_path }

  path '/subject-access-request/template' do
    get 'Retrieves the SAR Mustache template for this service' do
      security [{ Bearer: [] }]

      tags 'Subject Access Request'
      description(
        [
          '* A valid Bearer token must be supplied in the Authorization header.',
          '* The role ROLE_SAR_DATA_ACCESS is required',
          '* Returns the plain-text Mustache template configured for the service'
        ].join("\n")
      )

      response '401', 'Request is not authorised' do
        metadata[:response][:schema] = { '$ref' => '#/components/schemas/SarError' }
        metadata[:response][:content] = {
          'application/json' => {
            schema: { '$ref' => '#/components/schemas/SarError' },
            examples: {
              error_example: {
                value: {
                  developerMessage: 'Valid authorisation token required',
                  errorCode: 1,
                  status: 401,
                  userMessage: 'Valid authorisation token required'
                }
              }
            }
          }
        }

        let(:Authorization) { nil }

        run_test!
      end

      response '403', 'Invalid token role' do
        metadata[:response][:schema] = { '$ref' => '#/components/schemas/SarError' }
        metadata[:response][:content] = {
          'application/json' => {
            schema: { '$ref' => '#/components/schemas/SarError' },
            examples: {
              error_example: {
                value: {
                  developerMessage: 'Invalid token role',
                  errorCode: 5,
                  status: 403,
                  userMessage: 'Invalid token role'
                }
              }
            }
          }
        }

        before do
          stub_decoded_token(authorities: %w[ROLE_FOOBAR])
        end

        run_test!
      end

      response '200', 'Template returned' do
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
