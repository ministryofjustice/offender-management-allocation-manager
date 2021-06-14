require 'rails_helper'

RSpec.describe CaseloadHandoversController, :allocation, type: :controller do
  let(:prison) { create(:prison).code }
  let(:staff_id) { 456_987 }
  let(:not_signed_in) { 123_456 }
  let(:poms) {
    [
        build(:pom,
              firstName: 'Alice',
              staffId:  staff_id,
              position: RecommendationService::PRISON_POM),
        build(:pom,
              firstName: 'John',
              staffId:  not_signed_in,
              position: RecommendationService::PRISON_POM)
    ]
  }
  let(:pom) { poms.first }

  before do
    stub_poms(prison, poms)
  end

  describe '#index' do
    let(:handover_offender) { build(:nomis_offender, sentence: attributes_for(:sentence_detail, automaticReleaseDate: Time.zone.today + 31.weeks)) }
    let(:offender) { build(:nomis_offender, sentence: attributes_for(:sentence_detail, automaticReleaseDate: Time.zone.today + 13.weeks)) }
    let(:case_allocation) { 'CRC' }

    before do
      stub_offenders_for_prison(prison, [offender, handover_offender])

      create(:case_information, case_allocation: case_allocation, offender: build(:offender, nomis_offender_id: offender.fetch(:offenderNo)))
      create(:allocation_history, nomis_offender_id: offender.fetch(:offenderNo), primary_pom_nomis_id: pom.staffId, prison: prison)

      create(:case_information, case_allocation: case_allocation, offender: build(:offender, nomis_offender_id: handover_offender.fetch(:offenderNo)))
      create(:allocation_history, nomis_offender_id: handover_offender.fetch(:offenderNo), primary_pom_nomis_id: pom.staffId, prison: prison)
    end

    context 'with POM role' do
      before do
        stub_signed_in_pom(prison, pom.staffId, 'alice')
      end

      it 'retrieves just offenders due for handover' do
        get :index, params: { prison_id: prison, staff_id: staff_id }
        expect(response).to be_successful
        expect(assigns(:offenders).map(&:offender_no)).to match_array([offender.fetch(:offenderNo)])
      end
    end

    context 'with POM and SPO roles' do
      before do
        stub_signed_in_spo_pom(prison, pom.staffId, 'alice')
      end

      render_views

      it 'retrieves just offenders due for handover' do
        get :index, params: { prison_id: prison, staff_id: staff_id }
        expect(response).to have_http_status(200)
        expect(response).to be_successful
        expect(assigns(:offenders).map(&:offender_no)).to match_array([offender.fetch(:offenderNo)])
      end
    end
  end
end
