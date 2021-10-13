# frozen_string_literal: true

require 'rails_helper'

RSpec.describe DebuggingController, type: :controller do
  let(:prison) { create(:prison) }
  let(:prison_id) { prison.code }

  before do
    stub_sso_data(prison_id, roles: [SsoIdentity::SPO_ROLE, SsoIdentity::ADMIN_ROLE])
  end

  context 'when debugging an offender' do
    let(:offender_no) { 'G7806VO' }
    let(:pom_staff_id) { 543_453 }
    let(:primary_pom_name) { 'Jenae Sporer' }

    it 'can show debugging information for a specific offender' do
      stub_offender(build(:nomis_offender, agencyId: prison.code, sentence: attributes_for(:sentence_detail, :indeterminate), offenderNo: offender_no))

      stub_movements_for offender_no, [attributes_for(:movement, offenderNo: offender_no,
                                       fromAgency: "LEI",
                                       toAgency: prison_id,
                                       movementType: "TRN",
                                       directionCode: "IN")], movement_types: ['ADM', 'TRN', 'REL']

      create(:case_information, offender: build(:offender, nomis_offender_id: offender_no))
      create(:allocation_history, prison: prison.code, nomis_offender_id: offender_no, primary_pom_nomis_id: pom_staff_id, primary_pom_name: primary_pom_name)

      get :debugging, params: { prison_id: prison_id, offender_no: offender_no }

      expect(response.status).to eq(200)
      expect(response).to be_successful
      expect(response).to render_template("debugging/debugging")

      offender = assigns(:offender)
      expect(offender.indeterminate_sentence?).to be true

      allocation = assigns(:allocation)
      expect(allocation.primary_pom_name).to eq primary_pom_name

      override = assigns(:override)
      expect(override).to eq nil

      movements = assigns(:movements)
      expect(movements.movement_type).to eq "TRN"
      expect(movements.from_agency).to eq "LEI"
      expect(movements.to_agency).to eq prison_id
    end
  end
end
