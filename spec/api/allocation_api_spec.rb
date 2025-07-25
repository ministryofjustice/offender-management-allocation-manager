# frozen_string_literal: true

require 'swagger_helper'

describe 'Allocation API' do
  let(:Authorization) { "Bearer TEST_TOKEN" }
  let(:staff_id) { 485_926 }

  path '/api/allocation/{nomsNumber}' do
    get 'Retrieves the current allocation for an offender' do
      tags 'Allocations'
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
          allow_any_instance_of(Api::AllocationApiController).to receive(:verify_token)
        end

        response '200', 'Offender is allocated' do
          security [Bearer: []]
          schema required: %w[primary_pom secondary_pom],
                 type: :object,
                 properties: {
                   primary_pom: {
                     type: :object,
                     properties: {
                       staff_id: { type: :integer },
                       name: { type: :string }
                     }
                   },
                   secondary_pom: {
                     type: :object,
                     properties: {
                       staff_id: { type: :integer },
                       name: { type: :string }
                     }
                   }
                 }

          let(:nomsNumber) { 'G7266VD' }
          let!(:allocation) do
            create(:allocation_history, prison: 'LEI', nomis_offender_id: nomsNumber, primary_pom_name: 'OLD_NAME, MOIC')
          end

          run_test! do |_|
            primary_pom = JSON.parse(response.body)['primary_pom']
            secondary_pom = JSON.parse(response.body)['secondary_pom']

            expect(primary_pom['staff_id']).to eq(staff_id)
            expect(primary_pom['name']).to eq('OLD_NAME, MOIC')

            expect(secondary_pom).to eq({})
          end
        end

        response '404', 'Allocation for offender not found' do
          security [Bearer: []]
          schema '$ref' => '#/components/schemas/Status'

          let(:nomsNumber) { 'A1111AA' }
          run_test!
        end
      end
    end
  end

  path '/api/allocation/{nomsNumber}/primary_pom' do
    get 'Retrieves the primary POM for an offender' do
      tags 'Allocations'
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
          allow_any_instance_of(Api::AllocationApiController).to receive(:verify_token)

          stub_pom(
            build(:pom, staffId: staff_id, firstName: 'MOIC', lastName: 'POM', primaryEmail: 'test@example.com')
          )
        end

        response '200', 'Offender is allocated' do
          security [Bearer: []]
          schema required: %w[manager prison],
                 type: :object,
                 properties: {
                   manager: {
                     type: :object,
                     properties: {
                       code: { type: :integer },
                       forename: { type: :string },
                       surname: { type: :string }
                     }
                   },
                   prison: {
                     type: :object,
                     properties: {
                       code: { type: :string }
                     }
                   }
                 }
          let(:nomsNumber) { 'G7266VD' }
          let!(:allocation) do
            create(:allocation_history, prison: 'LEI', nomis_offender_id: nomsNumber, primary_pom_name: 'OLD_NAME, MOIC')
          end

          run_test! do |_|
            manager = JSON.parse(response.body)['manager']
            prison = JSON.parse(response.body)['prison']

            expect(manager['code']).to eq(staff_id)

            # details coming from the prison-api staff endpoint instead of the allocation DB record
            expect(manager['forename']).to eq('MOIC')
            expect(manager['surname']).to eq('POM')
            expect(manager['email']).to eq('test@example.com')

            expect(prison['code']).to eq('LEI')
          end
        end

        response '404', 'Allocation for offender not found' do
          security [Bearer: []]
          schema '$ref' => '#/components/schemas/Status'

          let(:nomsNumber) { 'A1111AA' }
          run_test!
        end
      end
    end
  end
end
