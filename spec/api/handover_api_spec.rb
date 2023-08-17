# frozen_string_literal: true

require 'swagger_helper'

describe 'Handover API', vcr: { cassette_name: 'prison_api/handover_api' } do
  let(:Authorization) { 'Bearer TEST_TOKEN' }

  before do
    allow(Api::Handover).to receive(:[])
  end

  path '/api/handovers/{nomsNumber}' do
    get 'Retrieves the handover information for an offender' do
      tags 'Handovers'
      produces 'application/json'
      parameter name: :nomsNumber, in: :path, schema: { '$ref' => '#/components/schemas/NomsNumber' }

      describe 'when not authorised' do
        response '401', 'Request is not authorised' do
          security [Bearer: []]
          schema '$ref' => '#/components/schemas/Status'

          let(:nomsNumber) { 'A1111AA' }
          run_test!
        end
      end

      describe 'when authorised' do
        before do
          allow_any_instance_of(Api::HandoversApiController).to receive(:verify_token)
        end

        response '200', 'Handover information successfully found' do
          security [Bearer: []]
          schema required: %w[nomsNumber handoverDate responsibility],
                 type: :object,
                 properties: {
                   nomsNumber: { '$ref' => '#/components/schemas/NomsNumber' },
                   handoverDate: { type: :string, format: :date },
                   responsibility: { type: :string, pattern: '^POM|COM$' },
                 }

          let(:nomsNumber) { 'G7266VD' }
          let(:body) do
            {
              'nomsNumber' => nomsNumber,
              'handoverStartDate' => '2021-12-01',
              'handoverDate' => '2021-12-01',
              'responsibility' => 'COM'
            }
          end

          before do
            allow(Api::Handover).to receive(:[]).with(nomsNumber).and_return(body)
          end

          run_test! do |_|
            expect(JSON.parse(response.body)).to eq body
          end
        end

        response '404', 'Handover information for offender not found' do
          security [Bearer: []]
          schema '$ref' => '#/components/schemas/Status'

          let(:nomsNumber) { 'A1111AA' }
          run_test!
        end
      end
    end
  end
end
