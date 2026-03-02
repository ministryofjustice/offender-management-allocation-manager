require 'rails_helper'

RSpec.describe CoworkingController, :allocation, type: :controller do
  let(:prison) { create(:prison).code }
  let(:primary_pom) { build(:pom) }
  let(:offender) { build(:nomis_offender, prisonId: prison) }
  let(:offender_no) { offender.fetch(:prisonerNumber) }
  let(:new_secondary_pom) { build(:pom) }

  before do
    stub_sso_data(prison)
    stub_offender(offender)
    create(:case_information, offender: build(:offender, nomis_offender_id: offender_no))

    stub_filtered_pom(prison, primary_pom)
    stub_filtered_pom(prison, new_secondary_pom)

    stub_offenders_for_prison(prison, [offender])
    stub_community_offender(offender_no, build(:community_data))
  end

  context 'when there is an existing invalid co-worker' do
    before do
      stub_user('user', primary_pom.staffId)

      create(:allocation_history, prison: prison,
                                  nomis_offender_id: offender_no,
                                  primary_pom_nomis_id: primary_pom.staffId,
                                  secondary_pom_nomis_id: secondary_pom.staffId)

      session[:latest_allocation_details] = {}
    end

    let(:user) { build(:pom) }
    let(:secondary_pom) { build(:pom) }

    it 'allocates' do
      post :create, params: { prison_id: prison, coworking_allocations: { nomis_offender_id: offender_no, nomis_staff_id: new_secondary_pom.staffId } }
      expect(response).to redirect_to(allocated_prison_prisoners_path(prison))
      expect(AllocationHistory.find_by(nomis_offender_id: offender_no).secondary_pom_nomis_id).to eq(new_secondary_pom.staffId)
    end

    it 'passes message and stores additional notes' do
      message = 'Needs support'
      expect(AllocationService).to receive(:allocate_secondary).with(
        hash_including(
          nomis_offender_id: offender_no,
          secondary_pom_nomis_id: new_secondary_pom.staffId.to_s,
          created_by_username: 'user',
          message: message
        )
      ).and_call_original

      post :create, params: { prison_id: prison, coworking_allocations: { nomis_offender_id: offender_no, nomis_staff_id: new_secondary_pom.staffId, message: message } }

      expect(session[:latest_allocation_details][:additional_notes]).to eq(message)
    end
  end

  describe '#confirm' do
    before do
      get :confirm, params: {
        "prison_id" => prison,
        "nomis_offender_id" => offender_no,
        "primary_pom_id" => primary_pom.staffId,
        "secondary_pom_id" => new_secondary_pom.staffId
      }
    end

    it 'returns success' do
      expect(response.code).to eq('200')
    end

    it 'stores offender details' do
      expect(session).to have_key(:latest_allocation_details)
      expect(session[:latest_allocation_details]).to include(prisoner_number: offender_no)
    end

    it 'stores allocation details in instance variable' do
      expect(assigns(:latest_allocation_details)).to include(prisoner_number: offender_no)
    end
  end

  describe '#destroy' do
    before do
      create(:allocation_history, prison: prison, nomis_offender_id: offender_no,
                                  primary_pom_nomis_id: primary_pom.staffId,
                                  secondary_pom_nomis_id: new_secondary_pom.staffId,
                                  secondary_pom_name: secondary_pom_name)

      allow(EmailService).to receive(:send_cowork_deallocation_email)
      allow(controller.helpers).to receive(:prisoner_path_for_role).and_return('/prisoners/path')
    end

    let(:allocation) { AllocationHistory.last }
    let(:secondary_pom_name) { 'Bloggs, Fred' }

    it 'sends a deallocation_email' do
      delete :destroy, params: { prison_id: prison, nomis_offender_id: allocation.nomis_offender_id }

      aggregate_failures do
        expect(response).to redirect_to('/prisoners/path')
        expect(EmailService).to have_received(:send_cowork_deallocation_email).with(
          allocation: allocation,
          pom_nomis_id: primary_pom.staffId,
          secondary_pom_name: secondary_pom_name
        )
        expect(flash[:notice]).to include(secondary_pom_name)
        expect(flash[:notice]).to include('removed as co-working POM')
      end
    end

    context 'when the secondary pom name is missing' do
      let(:secondary_pom_name) { nil }

      it 'does not send an email or set a notice' do
        delete :destroy, params: { prison_id: prison, nomis_offender_id: allocation.nomis_offender_id }

        aggregate_failures do
          expect(response).to redirect_to('/prisoners/path')
          expect(EmailService).not_to have_received(:send_cowork_deallocation_email)
          expect(flash[:notice]).to be_nil
        end
      end
    end

    context 'when the secondary pom is present but the primary pom is missing' do
      before do
        allocation.update!(primary_pom_nomis_id: nil)
      end

      it 'does not send an email' do
        delete :destroy, params: { prison_id: prison, nomis_offender_id: allocation.nomis_offender_id }

        aggregate_failures do
          expect(response).to redirect_to('/prisoners/path')
          expect(EmailService).not_to have_received(:send_cowork_deallocation_email)
          expect(flash[:notice]).to include(secondary_pom_name)
          expect(flash[:notice]).to include('removed as co-working POM')
        end
      end
    end
  end
end
