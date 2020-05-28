# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CaseloadController, type: :controller do
  let(:prison) { build(:prison).code }
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
    stub_signed_in_pom(prison, pom.staffId, 'alice')
  end

  describe '#handover_start' do
    before do
      stub_offenders_for_prison(prison, [offender])
      create(:case_information, case_allocation: case_allocation, nomis_offender_id: offender.fetch(:offenderNo))
      create(:allocation, nomis_offender_id: offender.fetch(:offenderNo), primary_pom_nomis_id: pom.staffId, prison: prison)
    end

    context 'when NPS' do
      before do
        stub_sso_data(prison, 'alice')
      end

      let(:today_plus_36_weeks) { (Time.zone.today + 36.weeks).to_s }
      let(:offender) { build(:nomis_offender, sentence: build(:nomis_sentence_detail, paroleEligibilityDate: today_plus_36_weeks)) }
      let(:case_allocation) { 'NPS' }

      it 'can pull back a NPS offender due for handover' do
        get :handover_start, params: { prison_id: prison, staff_id: staff_id }
        expect(response).to be_successful
        expect(assigns(:upcoming_handovers).map(&:offender_no)).to match_array([offender.fetch(:offenderNo)])
      end
    end

    context 'when CRC' do
      let(:offender) { build(:nomis_offender, sentence: build(:nomis_sentence_detail, automaticReleaseDate: today_plus_13_weeks)) }
      let(:case_allocation) { 'CRC' }
      let(:today_plus_13_weeks) { (Time.zone.today + 13.weeks).to_s }

      it 'can pull back a CRC offender due for handover' do
        get :handover_start, params: { prison_id: prison, staff_id: staff_id }
        expect(response).to be_successful
        expect(assigns(:upcoming_handovers).map(&:offender_no)).to match_array([offender.fetch(:offenderNo)])
      end
    end
  end

  context 'with 3 offenders', :versioning do
    let(:today) { Time.zone.today }
    let(:yesterday) { Time.zone.today - 1.day }

    let(:offenders) { build_list(:nomis_offender, 3).sort_by { |x| x.fetch(:lastName) } }

    before do
      # we need 3 data points - 1 in, 1 out on ROTL, 1 out on ROTL and returned.
      movements = [
        { offenderNo: offenders.first.fetch(:offenderNo),
          directionCode: 'OUT',
          createDateTime: today },
        { offenderNo: offenders.last.fetch(:offenderNo),
          directionCode: 'OUT',
          createDateTime: yesterday },
        { offenderNo: offenders.last.fetch(:offenderNo),
          directionCode: 'IN',
          createDateTime: today }
      ]

      stub_offenders_for_prison(prison, offenders, movements)

      # Need to create history records because AllocatedOffender#new_case? doesn't cope otherwise
      offenders.each do |offender|
        alloc = create(:allocation, nomis_offender_id: offender.fetch(:offenderNo), primary_pom_nomis_id: pom.staffId, prison: prison)
        alloc.update!(primary_pom_nomis_id: pom.staffId,
                      event: Allocation::REALLOCATE_PRIMARY_POM,
                      event_trigger: Allocation::USER)
      end
    end

    describe '#index' do
      before do
        stub_sso_data(prison, 'alice')
      end

      context 'when user is an SPO' do
        before do
          stub_sso_data(prison, 'alice')
        end

        it 'returns the caseload for an SPO' do
          get :index, params: { prison_id: prison, staff_id: staff_id }
          expect(response).to be_successful

          expect(assigns(:allocations).map(&:nomis_offender_id)).to match_array(offenders.map { |o| o.fetch(:offenderNo) })
        end
      end

      context 'when user is a different POM to the one signed in' do
        before do
          stub_signed_in_pom(prison, staff_id, 'alice')
        end

        it 'cant see the caseload' do
          get :index, params: { prison_id: prison, staff_id: not_signed_in }
          expect(response).to redirect_to('/401')
        end
      end

      context 'when user is the signed in POM' do
        it 'returns the caseload' do
          get :index, params: { prison_id: prison, staff_id: staff_id }
          expect(response).to be_successful

          expect(assigns(:allocations).map(&:nomis_offender_id)).to match_array(offenders.map { |o| o.fetch(:offenderNo) })
        end
      end
    end

    describe '#new' do
      before do
        stub_sso_data(prison, 'alice')
      end

      it 'returns the caseload' do
        get :new, params: { prison_id: prison, staff_id: staff_id }
        expect(response).to be_successful

        expect(assigns(:new_cases).map(&:nomis_offender_id)).to match_array(offenders.map { |o| o.fetch(:offenderNo) })
      end
    end
  end
end
