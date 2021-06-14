# frozen_string_literal: true

require 'rails_helper'

RSpec.describe DebuggingController, type: :controller do
  let(:prison) { create(:prison) }
  let(:prison_id) { prison.code }

  before do
    stub_sso_data(prison_id, roles: [SsoIdentity::SPO_ROLE, SsoIdentity::ADMIN_ROLE])
  end

  context 'when debugging at a prison level' do
    let(:offenders) {
      [
        build(:nomis_offender),
        build(:nomis_offender),
        build(:nomis_offender, dateOfBirth: Time.zone.today - 15.years),
        build(:nomis_offender, sentence: attributes_for(:sentence_detail, releaseDate: nil,
                                                        paroleEligibilityDate: nil, homeDetentionCurfewEligibilityDate: nil, tariffDate: nil))
      ]
    }

    before do
      stub_request(:post, "#{ApiHelper::T3}/movements/offenders?latestOnly=false&movementTypes=TRN").
        to_return(body: [].to_json)

      stub_offenders_for_prison(prison_id, offenders)

      create(:case_information, offender: build(:offender, nomis_offender_id: offenders.first.fetch(:offenderNo)))

      create(:case_information, offender: build(:offender, nomis_offender_id: offenders.second.fetch(:offenderNo)))
      create(:allocation_history, prison: prison_id, nomis_offender_id: offenders.second.fetch(:offenderNo))
    end

    it 'can show debugging information for an entire prison' do
      get :prison_info, params: { prison_id: prison_id }
      expect(response.status).to eq(200)
      expect(response).to be_successful

      expect(assigns(:prison_title)).to eq(prison.name)
      expect(assigns(:filtered_offenders_count)).to eq(2)
      expect(assigns(:unfiltered_offenders_count)).to eq(4)

      filtered_offenders = assigns(:filtered)
      expect(filtered_offenders[:under18].count).to eq(1)
      expect(filtered_offenders[:under18].first.first_name).to eq(offenders.third.fetch(:firstName))
      expect(filtered_offenders[:unsentenced].count).to eq(1)
    end
  end

  context 'when debugging an offender' do
    let(:offender_no) { 'G7806VO' }
    let(:pom_staff_id) { 543_453 }
    let(:primary_pom_name) { 'Jenae Sporer' }

    it 'can show debugging information for a specific offender' do
      stub_offender(build(:nomis_offender, sentence: attributes_for(:sentence_detail, :indeterminate), offenderNo: offender_no))

      stub_request(:post, "#{ApiHelper::T3}/movements/offenders?movementTypes=ADM&movementTypes=TRN&movementTypes=REL&latestOnly=false").
        with(
          body: "[\"G7806VO\"]").
        to_return(body: [{ offenderNo: offender_no,
                                        fromAgency: "LEI",
                                        toAgency: prison_id,
                                        movementType: "TRN",
                                        directionCode: "IN" }].to_json)

      create(:case_information, offender: build(:offender, nomis_offender_id: offender_no))
      create(:allocation_history, nomis_offender_id: offender_no, primary_pom_nomis_id: pom_staff_id, primary_pom_name: primary_pom_name)

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
