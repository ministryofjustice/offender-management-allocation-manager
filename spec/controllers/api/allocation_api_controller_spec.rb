require 'rails_helper'

RSpec.describe Api::AllocationApiController, :allocation, type: :controller do
  shared_examples 'returns 404' do |message|
    it 'returns 404 with correct message' do
      expect(response).to have_http_status(:not_found)
      expect(JSON.parse(response.body)).to eq("message" => message, "status" => "error")
    end
  end

  let(:prison) { create(:prison) }
  let(:primary_pom) { build(:pom) }
  let(:secondary_pom) { build(:pom) }

  let(:co_working_allocation) do
    create(
      :allocation_history,
      :co_working,
      prison: prison.code,
      primary_pom_nomis_id: primary_pom.staff_id,
      secondary_pom_nomis_id: secondary_pom.staff_id,
      nomis_offender_id: offender.fetch(:prisonerNumber)
    )
  end

  before do
    allow(controller).to receive(:verify_token)

    stub_pom(primary_pom)
    stub_pom(secondary_pom)
    stub_offender(offender)
    stub_auth_token
    allow_any_instance_of(DomainEvents::Event).to receive(:publish).and_return(nil)
  end

  describe '#show' do
    describe 'when a pom has been allocated an offender' do
      before { co_working_allocation }

      context 'when an offender is currently serving a sentence' do
        let(:offender) { build(:nomis_offender, prisonId: prison.code,  sentence: attributes_for(:sentence_detail)) }

        it 'returns both pom allocation details' do
          get :show, params: { offender_no: offender.fetch(:prisonerNumber) }

          expect(response).to have_http_status(:ok)
          expect(JSON.parse(response.body)).to eq("primary_pom" => { "name" => primary_pom.full_name.to_s, "staff_id" => primary_pom.staff_id },
                                                  "secondary_pom" => {  "name" => secondary_pom.full_name.to_s, "staff_id" => secondary_pom.staff_id })
        end
      end

      context 'when an offender has finished their sentence' do
        # currently an offender is not able to be unallocated from a pom. As a result the the pom remains on the DPS
        # quick look screen once an offenders sentence has finished. This is a quick fix to stop this happening.
        let(:offender) { build(:nomis_offender, prisonId: prison.code,  sentence: attributes_for(:sentence_detail, :unsentenced)) }

        before do
          get :show, params: { offender_no: offender.fetch(:prisonerNumber) }
        end

        it_behaves_like 'returns 404', 'Not allocated'
      end

      context 'when an offender is no longer returned from prison API but has case information' do
        # if an offender has case information but is not being returned from the prison API as a valid
        # inmate, return the expected 404 status code
        let(:offender) { build(:nomis_offender, prisonId: prison.code,  sentence: attributes_for(:sentence_detail)) }

        before do
          stub_nil_offender
          get :show, params: { offender_no: offender.fetch(:prisonerNumber) }
        end

        it_behaves_like 'returns 404', 'Not allocated'
      end
    end
  end

  describe '#primary_pom' do
    let(:expected_response) do
      {
        manager: {
          code: primary_pom.staff_id,
          forename: primary_pom.first_name,
          surname: primary_pom.last_name
        },
        prison: {
          code: prison.code
        }
      }.with_indifferent_access
    end

    describe 'when a pom has been allocated an offender' do
      before do
        co_working_allocation
        allow(HmppsApi::PrisonApi::PrisonOffenderManagerApi).to receive(:staff_detail)
          .and_return(primary_pom)
      end

      context 'when an offender is currently serving a sentence' do
        let(:offender) { build(:nomis_offender, prisonId: prison.code,  sentence: attributes_for(:sentence_detail)) }

        it 'returns primary pom allocation details' do
          get :primary_pom, params: { offender_no: offender.fetch(:prisonerNumber) }

          expect(response).to have_http_status(:ok)
          expect(JSON.parse(response.body)).to eq(expected_response)
        end
      end

      context 'when an offender has finished their sentence' do
        let(:offender) { build(:nomis_offender, prisonId: prison.code,  sentence: attributes_for(:sentence_detail, :unsentenced)) }

        before do
          get :primary_pom, params: { offender_no: offender.fetch(:prisonerNumber) }
        end

        it_behaves_like 'returns 404', 'Not allocated'
      end

      context 'when an offender is no longer returned from prison API but has case information' do
        let(:offender) { build(:nomis_offender, prisonId: prison.code,  sentence: attributes_for(:sentence_detail)) }

        before do
          stub_nil_offender
          get :primary_pom, params: { offender_no: offender.fetch(:prisonerNumber) }
        end

        it_behaves_like 'returns 404', 'Not allocated'
      end
    end
  end
end
