# frozen_string_literal: true

require 'swagger_helper'

describe 'Handover API', vcr: { cassette_name: 'prison_api/handover_api' } do
  let(:Authorization) { 'Bearer TEST_TOKEN' }

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

        context 'when handover has been calculated' do
          before do
            create(
              :calculated_handover_date,
              offender: build(:offender, nomis_offender_id: nomsNumber),
              start_date: Date.new(2024, 6, 1),
              handover_date: Date.new(2024, 7, 1),
              responsibility: CalculatedHandoverDate::COMMUNITY_RESPONSIBLE,
              reason: :recall_case
            )
          end

          response '200', 'Handover information successfully found' do
            security [Bearer: []]
            schema required: %w[nomsNumber handoverDate responsibility responsibleComName responsibleComEmail responsiblePomName responsiblePomNomisId],
                   type: :object,
                   properties: {
                     nomsNumber: { '$ref' => '#/components/schemas/NomsNumber' },
                     handoverDate: { type: :string, format: :date },
                     responsibility: { type: :string, pattern: '^POM|COM$' },
                     responsibleComName: { type: :string, nullable: true },
                     responsibleComEmail: { type: :string, nullable: true },
                     responsiblePomName: { type: :string, nullable: true },
                     responsiblePomNomisId: { type: :string, nullable: true }
                   }

            let(:nomsNumber) { 'G7266VD' }
            let(:body) do
              {
                'nomsNumber' => nomsNumber,
                'handoverStartDate' => '2024-06-01',
                'handoverDate' => '2024-07-01',
                'responsibility' => 'COM',
                'responsibleComName' => nil,
                'responsibleComEmail' => nil,
                'responsiblePomName' => nil,
                'responsiblePomNomisId' => nil
              }
            end

            run_test! do |_|
              expect(JSON.parse(response.body)).to eq body
            end
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
