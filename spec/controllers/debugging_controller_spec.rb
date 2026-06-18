# frozen_string_literal: true

require 'rails_helper'

RSpec.describe DebuggingController, type: :controller do
  let(:prison) { create(:prison) }
  let(:prison_id) { prison.code }
  let(:offender_no) { 'G7806VO' }

  before do
    stub_sso_data(prison_id, roles: [SsoIdentity::SPO_ROLE, SsoIdentity::ADMIN_ROLE])
  end

  context 'when the offender is not known to the system' do
    render_views

    it 'shows a warning message on the debugging page' do
      get :debugging, params: { prison_id: prison_id, offender_no: offender_no }

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('not known to our system')
      expect(assigns(:offender)).to be_nil
    end

    it 'shows a warning message on the timeline page' do
      get :timeline, params: { prison_id: prison_id, offender_no: offender_no }

      expect(response).to have_http_status(:ok)
      expect(response.body).to include('not known to our system')
      expect(assigns(:log)).to be_nil
    end
  end

  context 'when debugging an offender' do
    let(:pom_staff_id) { 543_453 }
    let(:primary_pom_name) { 'Jenae Sporer' }

    before do
      create(:offender, nomis_offender_id: offender_no)
    end

    it 'can show debugging information for a specific offender' do
      stub_offender(build(:nomis_offender, prisonId: prison.code, sentence: attributes_for(:sentence_detail, :indeterminate), prisonerNumber: offender_no))

      stub_movements_for offender_no, [attributes_for(:movement, offenderNo: offender_no,
                                                                 fromAgency: "LEI",
                                                                 toAgency: prison_id,
                                                                 movementType: "TRN",
                                                                 directionCode: "IN")], movement_types: %w[ADM TRN REL]

      create(:case_information, offender: Offender.find_by(nomis_offender_id: offender_no))
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

    context 'when the offender is outside OMiC policy' do
      render_views

      it 'shows the page with an outside OMiC policy message' do
        stub_offender(build(:nomis_offender, :outside_omic_policy, prisonId: prison.code, prisonerNumber: offender_no))

        stub_movements_for offender_no, [attributes_for(:movement, offenderNo: offender_no,
                                                                   fromAgency: 'LEI',
                                                                   toAgency: prison_id,
                                                                   movementType: 'TRN',
                                                                   directionCode: 'IN')], movement_types: %w[ADM TRN REL]

        get :debugging, params: { prison_id: prison_id, offender_no: offender_no }

        expect(response).to have_http_status(:ok)
        expect(response.body).to include('outside OMiC policy')
      end
    end

    context 'when rendering handover history comparisons' do
      render_views

      it 'renders the handover history comparison block' do
        stub_offender(build(:nomis_offender, prisonId: prison.code, sentence: attributes_for(:sentence_detail, :indeterminate), prisonerNumber: offender_no))

        stub_movements_for offender_no, [attributes_for(:movement, offenderNo: offender_no,
                                                                   fromAgency: 'LEI',
                                                                   toAgency: prison_id,
                                                                   movementType: 'TRN',
                                                                   directionCode: 'IN')], movement_types: %w[ADM TRN REL]

        offender = Offender.find_by(nomis_offender_id: offender_no)
        create(:case_information, offender:)
        create(:allocation_history, prison: prison.code, nomis_offender_id: offender_no, primary_pom_nomis_id: pom_staff_id, primary_pom_name: primary_pom_name)

        calculated_handover = build(:calculated_handover_date,
                                    offender:,
                                    nomis_offender_id: offender_no,
                                    responsibility: CalculatedHandoverDate::COMMUNITY_RESPONSIBLE,
                                    reason: :recall_case)
        calculated_handover.offender_attributes_to_archive = {
          'mappa_level' => 1,
          'recalled?' => false,
          'test_same_value' => 'same',
          'ldu_email_address' => 'pom@example.com',
          'team_name' => nil
        }
        calculated_handover.save!

        calculated_handover.offender_attributes_to_archive = {
          'mappa_level' => 2,
          'recalled?' => true,
          'test_same_value' => 'same',
          'ldu_email_address' => nil,
          'team_name' => nil
        }
        calculated_handover.update!(reason: :determinate_short)

        get :debugging, params: { prison_id: prison_id, offender_no: offender_no }

        expect(response).to have_http_status(:ok)
        expect(response.body).to include('Offender details recorded at this point')
        expect(response.body).to include('Before')
        expect(response.body).to include('After')
        expect(response.body).to include('Ldu email address')
        expect(response.body).to include('(unset)')
      end
    end
  end

  describe 'debugging the timeline of events' do
    before do
      create(:offender, nomis_offender_id: offender_no)

      create(:audit_event, nomis_offender_id: offender_no, created_at: 60.seconds.ago, tags: %w[event tag one])
      create(:audit_event, nomis_offender_id: offender_no, created_at: 30.seconds.ago, tags: %w[event tag two])
      create(:audit_event, nomis_offender_id: offender_no, created_at: 10.seconds.ago, tags: %w[event tag three])
    end

    it 'displays pertinent records descending in order of creation' do
      get :timeline, params: { prison_id:, offender_no: }

      log_items = assigns(:log)
      expect(log_items[0].then { [it.class, it.tags] }).to eq([AuditEvent, %w[event tag three]])
      expect(log_items[1].then { [it.class, it.tags] }).to eq([AuditEvent, %w[event tag two]])
      expect(log_items[2].then { [it.class, it.tags] }).to eq([AuditEvent, %w[event tag one]])
    end
  end
end
