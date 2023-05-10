# frozen_string_literal: true

require 'swagger_helper'

describe 'Offender Early Allocation API', vcr: { cassette_name: 'prison_api/offender_api' } do
  let(:Authorization) { "Bearer TEST_TOKEN" }

  path '/api/offenders/{nomsNumber}' do
    get 'Retrieves information for a prisoner including early allocation status' do
      tags 'Offenders'
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
          allow_any_instance_of(Api::OffendersController).to receive(:verify_token)
        end

        response '200', 'Offender has an early allocation' do
          security [Bearer: []]
          schema type: :object,
                 properties: {
                   offender_no: { '$ref' => '#/components/schemas/NomsNumber' },
                   nomsNumber: { '$ref' => '#/components/schemas/NomsNumber' },
                   early_allocation_eligibility_status: {
                     type: :boolean,
                     description: "true if prisoner is subject to early allocation, and so has an early handover date"
                   }
                 },
                 required: %w[offender_no nomsNumber early_allocation_eligibility_status]

          let(:nomsNumber) { 'G7266VD' }
          let!(:allocation) do
            create(:case_information, offender: build(:offender, nomis_offender_id: nomsNumber, early_allocations: build_list(:early_allocation, 1)))
          end

          run_test! do |_|
            expect(JSON.parse(response.body).fetch('nomsNumber')).to eq(nomsNumber)
            expect(JSON.parse(response.body).fetch('early_allocation_eligibility_status')).to eq(true)
          end
        end

        response '404', 'Offender not found' do
          security [Bearer: []]
          schema '$ref' => '#/components/schemas/Status'

          let(:nomsNumber) { 'A1111AA' }
          run_test!
        end
      end
    end
  end
end
