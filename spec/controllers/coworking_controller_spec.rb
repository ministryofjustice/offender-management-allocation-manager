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
    stub_poms(prison, [primary_pom, new_secondary_pom])
    stub_offenders_for_prison(prison, [offender])
    stub_community_offender(offender_no, build(:community_data))
    allow_any_instance_of(MpcOffender).to receive(:rosh_summary).and_return({ status: :missing })
  end

  context 'when there is an existing invalid co-worker' do
    before do
      stub_request(:get, "#{ApiHelper::T3}/staff/#{primary_pom.staffId}")
        .to_return(body: { 'firstName' => 'fred' }.to_json)
      stub_request(:get, "#{ApiHelper::T3}/staff/#{new_secondary_pom.staffId}")
        .to_return(body: { 'firstName' => 'bill' }.to_json)
      stub_pom_emails(user.staffId, [])

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
    end

    let(:allocation) { AllocationHistory.last }
    let(:secondary_pom_name) { 'Bloggs, Fred' }

    it 'sends a deallocation_email' do
      fakejob = double
      allow(fakejob).to receive(:deliver_later)

      expect(PomMailer).to receive(:deallocate_coworking_pom)
        .with(
          secondary_pom_name: secondary_pom_name,
          email_address: primary_pom.emails.first,
          nomis_offender_id: offender_no,
          offender_name: "#{offender.fetch(:lastName)}, #{offender.fetch(:firstName)}",
          pom_name: primary_pom.firstName.capitalize,
          url: Rails.application.routes.default_url_options[:host] + prison_staff_caseload_path(prison, primary_pom.staffId)
        )
        .and_return(fakejob)

      delete :destroy, params: { prison_id: prison, nomis_offender_id: allocation.nomis_offender_id }
      expect(response).to redirect_to(prison_prisoner_allocation_path(prison, allocation.nomis_offender_id))
    end
  end
end
