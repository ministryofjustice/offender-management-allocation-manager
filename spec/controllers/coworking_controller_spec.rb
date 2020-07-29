require 'rails_helper'

RSpec.describe CoworkingController, type: :controller do
  context 'when there is an existing invalid co-worker' do
    before do
      stub_sso_data(prison, username)
      stub_offender(offender)
      stub_offenders_for_prison(prison, [offender])
      stub_poms(prison, [primary_pom, new_secondary_pom])
      stub_request(:get, "#{ApiHelper::T3}/staff/#{primary_pom.staffId}").
        to_return(body: { 'firstName' => 'fred' }.to_json)
      stub_request(:get, "#{ApiHelper::T3}/staff/#{new_secondary_pom.staffId}").
        to_return(body: { 'firstName' => 'bill' }.to_json)
      stub_request(:get, "#{ApiHelper::T3}/users/#{username}").
        to_return(body: { 'staffId': user.staffId }.to_json)
      stub_pom_emails(user.staffId, [])

      create(:allocation, prison: prison,
             nomis_offender_id: offender_no,
             primary_pom_nomis_id: primary_pom.staffId,
             secondary_pom_nomis_id: secondary_pom.staffId)
    end

    let(:username) { 'alice' }
    let(:user) { build(:pom) }
    let(:prison) { build(:prison).code }
    let(:primary_pom) { build(:pom) }
    let(:secondary_pom) { build(:pom) }
    let(:new_secondary_pom) { build(:pom) }
    let(:offender) { build(:nomis_offender) }
    let(:offender_no) { offender.fetch(:offenderNo) }

    it 'allocates' do
      post :create, params: { prison_id: prison, coworking_allocations: { nomis_offender_id: offender_no, nomis_staff_id: new_secondary_pom.staffId } }
      expect(response).to redirect_to(prison_summary_unallocated_path(prison))
      expect(Allocation.find_by(nomis_offender_id: offender_no).secondary_pom_nomis_id).to eq(new_secondary_pom.staffId)
    end
  end
end
