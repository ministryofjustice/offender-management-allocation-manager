# frozen_string_literal: true

require 'swagger_helper'

describe 'Offender Early Allocation API', vcr: { cassette_name: 'prison_api/offender_api' } do
  let(:Authorization) { "Bearer TEST_TOKEN" }

  path '/api/offenders/{offender_no}' do
    get 'Retrieves the early allocation status for an prisoner' do
      tags 'Early Allocations'
      produces 'application/json'
      parameter name: :offender_no, in: :path, type: :string

      describe 'when not authorised' do
        response '401', 'Request is not authorised' do
          security [Bearer: []]
          schema type: :object,
                 properties: {
                   status: { type: :string },
                   message: { type: :string }
                 }

          let(:offender_no) { 'A1111AA' }
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
                   offender_no: { type: :string },
                   early_allocation_eligibility_status: {
                     type: :boolean,
                     description: "true if prisoner is subject to early allocation, and so has an early handover date"
                   }
                 },
                 required: %w[offender_no early_allocation_eligibility_status]

          let(:offender_no) { 'G7266VD' }
          let!(:allocation) do
            create(:case_information, offender: build(:offender, nomis_offender_id: offender_no, early_allocations: build_list(:early_allocation, 1)))
          end

          run_test! do |_|
            expect(JSON.parse(response.body).fetch('offender_no')).to eq(offender_no)
            expect(JSON.parse(response.body).fetch('early_allocation_eligibility_status')).to eq(true)
          end
        end

        response '404', 'offender not found' do
          security [Bearer: []]
          schema type: :object,
                 properties: {
                   status: { type: :string },
                   message: { type: :string }
                 }

          let(:offender_no) { 'A1111AA' }
          run_test!
        end
      end
    end
  end
end
