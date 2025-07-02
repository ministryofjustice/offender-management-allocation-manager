require 'rails_helper'

RSpec.describe Api::AllocationApiController, :allocation, type: :controller do
  shared_examples 'returns 404' do |message|
    it 'returns 404 with correct message' do
      expect(response).to have_http_status(:not_found)
      expect(JSON.parse(response.body)).to eq("message" => message, "status" => "error")
    end
  end

  let(:prison_code) { 'LEI' }
  let(:offender_no) { 'G8191UI' }
  let(:primary_pom) { build(:pom, firstName: 'JOHN', lastName: 'DOE') }
  let(:secondary_pom) { build(:pom, firstName: 'ZACHERY', lastName: 'SCHMELER') }

  let(:co_working_allocation) do
    create(
      :allocation_history,
      :co_working,
      prison: prison_code,
      primary_pom_nomis_id: primary_pom&.staff_id,
      secondary_pom_nomis_id: secondary_pom&.staff_id,
      nomis_offender_id: offender_no
    )
  end

  before do
    allow(controller).to receive(:verify_token)
  end

  describe '#show' do
    describe 'when a pom has been allocated an offender' do
      before { co_working_allocation }

      it 'returns both pom allocation details' do
        get :show, params: { offender_no: }

        expect(response).to have_http_status(:ok)
        expect(
          JSON.parse(response.body)
        ).to eq(
          "primary_pom" => { "name" => co_working_allocation.primary_pom_name, "staff_id" => co_working_allocation.primary_pom_nomis_id },
          "secondary_pom" => { "name" => co_working_allocation.secondary_pom_name, "staff_id" => co_working_allocation.secondary_pom_nomis_id }
        )
      end

      context 'when allocation is not active' do
        let(:primary_pom) { nil }

        before do
          get :show, params: { offender_no: }
        end

        it_behaves_like 'returns 404', 'Not allocated'
      end
    end

    context 'when an offender is not found in the allocations history' do
      before do
        get :show, params: { offender_no: 'G8191XX' }
      end

      it_behaves_like 'returns 404', 'Not ready for allocation'
    end
  end

  describe '#primary_pom' do
    let(:email_address) { 'test@example.com' }
    let(:expected_response) do
      {
        manager: {
          code: primary_pom.staff_id,
          forename: primary_pom.first_name,
          surname: primary_pom.last_name,
          email: email_address
        },
        prison: {
          code: prison_code
        }
      }.with_indifferent_access
    end

    describe 'when a pom has been allocated an offender' do
      before do
        co_working_allocation
      end

      context 'when there is primary pom' do
        before do
          stub_pom(primary_pom, emails: [email_address])
        end

        it 'returns primary pom allocation details' do
          get :primary_pom, params: { offender_no: }

          expect(response).to have_http_status(:ok)
          expect(JSON.parse(response.body)).to eq(expected_response)
        end
      end

      context 'when allocation is not active' do
        let(:primary_pom) { nil }

        before do
          get :primary_pom, params: { offender_no: }
        end

        it_behaves_like 'returns 404', 'Not allocated'
      end
    end

    context 'when an offender is not found in the allocations history' do
      before do
        get :primary_pom, params: { offender_no: 'G8191XX' }
      end

      it_behaves_like 'returns 404', 'Not ready for allocation'
    end
  end
end
