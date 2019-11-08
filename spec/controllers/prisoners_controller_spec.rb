require 'rails_helper'

RSpec.describe PrisonersController, type: :controller do
  let(:prison) { 'WEI' }
  let(:username) { 'POM_USER' }
  let(:staff_id) { 444_555 }
  let(:offender) { assigns(:prisoner) }

  before do
    stub_sso_pom_data(prison, username)
    stub_signed_in_pom(staff_id, username)

    stub_offender(nomis_offender_id, imprisonment_status: sentence_type)
    stub_request(:get, "https://keyworker-api-dev.prison.service.justice.gov.uk/key-worker/WEI/offender/#{nomis_offender_id}").
      to_return(status: 200, body: { staffId: staff_id }.to_json, headers: {})

    create(:case_information, nomis_offender_id: nomis_offender_id, mappa_level: 2)
  end

  context 'when not recalled' do
    let(:sentence_type) { 'SENT03' }
    let(:nomis_offender_id) { "G1234VV" }

    it 'shows handover dates' do
      get :show, params: { prison_id: prison, id: nomis_offender_id }
      expect(offender.handover_start_date).to eq([Date.new(2010, 6, 13), "NPS Determinate"])
      expect(offender.responsibility_handover_date).to eq([Date.new(2010, 6, 13), "NPS Determinate Mappa 2/3"])
    end
  end

  context 'when recalled' do
    let(:sentence_type) { 'LR' }
    let(:nomis_offender_id) { "G1234VX" }

    it 'doesnt show handover dates' do
      get :show, params: { prison_id: prison, id: nomis_offender_id }
      expect(offender.handover_start_date).to eq([nil, "Recalled"])
      expect(offender.responsibility_handover_date).to eq([nil, "Recalled"])
    end
  end
end
