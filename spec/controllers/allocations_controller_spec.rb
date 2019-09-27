require 'rails_helper'

RSpec.describe AllocationsController, type: :controller do
  let(:prison) { 'LEI' }

  let(:poms) {
    [
      {
        firstName: 'Alice',
        position: 'PRO'
      },
      {
        firstName: 'Bob',
        position: 'PRO'
      },
      {
        firstName: 'Clare',
        position: 'PO'
      },
      {
        firstName: 'Dave',
        position: 'PO'
      }
    ]
  }

  before do
    stub_sso_data(prison)

    stub_request(:get, "https://gateway.t3.nomis-api.hmpps.dsd.io/elite2api/api/staff/roles/LEI/role/POM").
      with(
        headers: {
          'Authorization' => 'Bearer token',
          'Page-Limit' => '100',
          'Page-Offset' => '0'
        }).
      to_return(status: 200, body: poms.to_json, headers: {})
  end

  def stub_offender(nomis_id)
    stub_request(:get, "https://gateway.t3.nomis-api.hmpps.dsd.io/elite2api/api/prisoners/#{nomis_id}").
      with(
        headers: {
          'Authorization' => 'Bearer token'
        }).
      to_return(status: 200, body: [{ offenderNo: nomis_id, gender: 'Male', latestBookingId: 754_207 }].to_json, headers: {})

    stub_request(:post, "https://gateway.t3.nomis-api.hmpps.dsd.io/elite2api/api/offender-sentences/bookings").
      with(
        body: "[754207]",
        headers: {
          'Content-Type' => 'application/json'
        }).
      to_return(status: 200, body: [{ offenderNo: nomis_id, bookingId: 754_207, sentenceDetail: {} }].to_json, headers: {})

    stub_request(:post, "https://gateway.t3.nomis-api.hmpps.dsd.io/elite2api/api/offender-assessments/CATEGORY").
      with(
        body: [nomis_id].to_json,
        headers: {
          'Content-Type' => 'application/json'
        }).
      to_return(status: 200, body: {}.to_json, headers: {})
    stub_request(:get, "https://gateway.t3.nomis-api.hmpps.dsd.io/elite2api/api/bookings/754207/mainOffence").
      with(
        headers: {
          'Authorization' => 'Bearer token'
        }).
      to_return(status: 200, body: {}.to_json, headers: {})
  end

  describe '#new' do
    let(:offender_no) { 'G7806VO' }

    before do
      stub_offender(offender_no)
    end

    context 'when tier A offender' do
      it 'serves recommended POMs' do
        create(:case_information, nomis_offender_id: offender_no, tier: 'A')

        get :new, params: { prison_id: prison, nomis_offender_id: offender_no }

        expect(response).to be_successful

        expect(assigns(:recommended_poms).map(&:first_name)).to match_array(%w[Clare Dave])
      end
    end

    context 'when tier D offender' do
      it 'serves recommended POMs' do
        create(:case_information, nomis_offender_id: offender_no, tier: 'D')

        get :new, params: { prison_id: prison, nomis_offender_id: offender_no }

        expect(response).to be_successful

        expect(assigns(:recommended_poms).map(&:first_name)).to match_array(%w[Alice Bob])
      end
    end
  end
end
