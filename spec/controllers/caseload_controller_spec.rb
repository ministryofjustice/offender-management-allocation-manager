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

  context 'with 3 offenders', :versioning do
    let(:today) { Time.zone.today }
    let(:yesterday) { Time.zone.today - 1.day }

    let(:offenders) { build_list(:nomis_offender, 3).sort_by { |x| x.fetch(:lastName) } }

    before do
      # we need 3 data points - 1 in, 1 out on ROTL, 1 out on ROTL and returned.
      movements = [
        attributes_for(:movement,
                       :rotl,
                       offenderNo: offenders.first.fetch(:offenderNo),
                       createDateTime: today.to_s),
        attributes_for(:movement,
                       :rotl,
                       offenderNo: offenders.last.fetch(:offenderNo),
                       createDateTime: yesterday.to_s),
        attributes_for(:movement,
                       offenderNo: offenders.last.fetch(:offenderNo),
                       createDateTime: today.to_s)
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
      context 'when user is an SPO' do
        before do
          stub_sso_data(prison)
        end

        it 'is allowed' do
          get :index, params: { prison_id: prison, staff_id: staff_id }
          expect(response).to be_successful
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
        before do
          stub_signed_in_pom(prison, staff_id, 'alice')
        end

        let(:allocations) { assigns(:allocations).index_by(&:nomis_offender_id) }

        before do
          get :index, params: { prison_id: prison, staff_id: staff_id }
        end

        it 'is allowed' do
          expect(response).to be_successful
        end

        it 'returns the caseload' do
          expect(assigns(:allocations).map(&:nomis_offender_id)).to match_array(offenders.map { |o| o.fetch(:offenderNo) })
        end

        it 'returns ROTL information' do
          expect(offenders.map { |o| allocations.fetch(o.fetch(:offenderNo)).latest_movement_date }).to eq [today, nil, nil]
        end
      end
    end

    describe '#new' do
      before do
        stub_sso_data(prison)
      end

      it 'returns the caseload' do
        get :new, params: { prison_id: prison, staff_id: staff_id }
        expect(response).to be_successful

        expect(assigns(:new_cases).map(&:nomis_offender_id)).to match_array(offenders.map { |o| o.fetch(:offenderNo) })
      end
    end
  end
end
