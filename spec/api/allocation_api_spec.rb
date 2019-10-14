# frozen_string_literal: true

require 'swagger_helper'

# rubocop:disable RSpec/DescribeClass
# The DescribeClass cop has been disabled as it is insists that the describe
# block contain the name of the tested class.  However rswag is using this
# text as part of the API documentation generated from these tests.
describe 'Allocation API' do
  let!(:private_key) { OpenSSL::PKey::RSA.generate 2048 }
  let!(:public_key) { Base64.strict_encode64(private_key.public_key.to_s) }
  let!(:payload) {
    {
      user_name: 'test-user',
      scope: ['read'],
      exp: 4.hours.from_now.to_i
    }
  }
  let!(:token) { JWT.encode payload, private_key, 'RS256' }

  before {
    allow(Rails.configuration).to receive(:nomis_oauth_public_key).and_return(public_key)
  }

  path '/api/allocation/{offender_no}' do
    get 'Retrieves the current allocation for an offender' do
      tags 'Allocations'
      produces 'application/json'
      parameter name: :offender_no, in: :path, type: :string

      response '200', 'Offender is allocated' do
        security [Bearer: {}]
        schema type: :object,
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
               },
               required: %w[primary_pom secondary_pom]

        let(:offender_no) { 'G4273GI' }
        let!(:allocation) {
          create(:allocation_version, nomis_offender_id: offender_no, primary_pom_name: 'Hyon Zboncak')
        }
        let(:Authorization) { "Bearer #{token}" }

        run_test! do |_|
          primary_pom = JSON.parse(response.body)['primary_pom']
          secondary_pom = JSON.parse(response.body)['secondary_pom']

          expect(primary_pom['staff_id']).to eq(485_752)
          expect(primary_pom['name']).to eq('Hyon Zboncak')

          expect(secondary_pom).to eq({})
        end
      end

      response '401', 'Request is not authorised' do
        security [Bearer: {}]
        schema type: :object,
               properties: {
                 status: { type: :string },
                 message: { type: :string }
               }

        let(:offender_no) { 'A1111AA' }
        let(:Authorization) { "Bearer missing" }
        run_test!
      end

      response '404', 'Allocation for offender not found' do
        security [Bearer: {}]
        schema type: :object,
               properties: {
                 status: { type: :string },
                 message: { type: :string }
               }

        let(:offender_no) { 'A1111AA' }
        let(:Authorization) { "Bearer #{token}" }
        run_test!
      end
    end
  end
end
# rubocop:enable RSpec/DescribeClass
