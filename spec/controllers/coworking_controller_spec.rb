require 'rails_helper'

RSpec.describe CoworkingController, type: :controller do
  let(:prison) { build(:prison).code }
  let(:primary_pom) { build(:pom) }
  let(:offender) { build(:nomis_offender) }
  let(:offender_no) { offender.fetch(:offenderNo) }
  let(:new_secondary_pom) { build(:pom) }

  before do
    stub_sso_data(prison)
    stub_offender(offender)
    stub_poms(prison, [primary_pom, new_secondary_pom])
    stub_offenders_for_prison(prison, [offender])
  end

  context 'when there is an existing invalid co-worker' do
    before do
      stub_request(:get, "#{ApiHelper::T3}/staff/#{primary_pom.staffId}").
        to_return(body: { 'firstName' => 'fred' }.to_json)
      stub_request(:get, "#{ApiHelper::T3}/staff/#{new_secondary_pom.staffId}").
        to_return(body: { 'firstName' => 'bill' }.to_json)
      stub_pom_emails(user.staffId, [])

      create(:allocation, prison: prison,
             nomis_offender_id: offender_no,
             primary_pom_nomis_id: primary_pom.staffId,
             secondary_pom_nomis_id: secondary_pom.staffId)
    end

    let(:user) { build(:pom) }
    let(:secondary_pom) { build(:pom) }

    it 'allocates' do
      post :create, params: { prison_id: prison, coworking_allocations: { nomis_offender_id: offender_no, nomis_staff_id: new_secondary_pom.staffId } }
      expect(response).to redirect_to(prison_summary_unallocated_path(prison))
      expect(Allocation.find_by(nomis_offender_id: offender_no).secondary_pom_nomis_id).to eq(new_secondary_pom.staffId)
    end
  end

  describe '#destroy' do
    before do
      create(:allocation, prison: prison, nomis_offender_id: offender_no,
             primary_pom_nomis_id: primary_pom.staffId,
             secondary_pom_nomis_id: new_secondary_pom.staffId,
             secondary_pom_name: secondary_pom_name)
    end

    let(:allocation) { Allocation.last }
    let(:secondary_pom_name) { 'Bloggs, Fred' }

    it 'sends a deallocation_email' do
      fakejob = double
      allow(fakejob).to receive(:deliver_later)

      expect(PomMailer).to receive(:deallocate_coworking_pom).
        with(
          secondary_pom_name: secondary_pom_name,
          email_address: primary_pom.emails.first,
          nomis_offender_id: offender_no,
          offender_name: "#{offender.fetch(:lastName)}, #{offender.fetch(:firstName)}",
          pom_name: primary_pom.firstName.capitalize,
          url: Rails.application.routes.default_url_options[:host] + prison_staff_caseload_index_path(prison, primary_pom.staffId)
        ).
        and_return(fakejob)

      delete :destroy, params: { prison_id: prison, nomis_offender_id: allocation.nomis_offender_id }
      expect(response).to redirect_to(prison_allocation_path(prison, allocation.nomis_offender_id))
    end
  end
end
