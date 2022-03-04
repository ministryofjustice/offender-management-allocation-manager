# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CaseloadController, type: :controller do
  let(:staff_id) { 456_987 }
  let(:not_signed_in) { 123_456 }
  let(:poms) do
    [
      build(:pom,
            firstName: 'Alice',
            staffId: staff_id,
            position: RecommendationService::PRISON_POM),
      build(:pom,
            firstName: 'John',
            staffId: not_signed_in,
            position: RecommendationService::PRISON_POM)
    ]
  end
  let(:pom) { poms.first }

  before do
    stub_poms(prison.code, poms)
    stub_signed_in_pom(prison.code, pom.staffId, 'alice')
  end

  context 'with 3 offenders' do
    let(:today) { Time.zone.today }
    let(:yesterday) { Time.zone.today - 1.day }

    let(:offenders) do
      [
        build(:nomis_offender, :rotl, complexityLevel: 'high'),
        build(:nomis_offender, complexityLevel: 'medium'),
        build(:nomis_offender, complexityLevel: 'low')
      ]
    end

    before do
      # we need 3 data points - 1 in, 1 out on ROTL, 1 out on ROTL and returned.
      movements = [
        attributes_for(:movement,
                       :rotl,
                       offenderNo: offenders.first.fetch(:prisonerNumber),
                       movementDate: today.to_s),
        attributes_for(:movement,
                       :rotl,
                       offenderNo: offenders.last.fetch(:prisonerNumber),
                       movementDate: yesterday.to_s),
        attributes_for(:movement,
                       offenderNo: offenders.last.fetch(:prisonerNumber),
                       movementDate: today.to_s)
      ]

      stub_offenders_for_prison(prison.code, offenders, movements)

      # Need to create history records because AllocatedOffender#new_case? doesn't cope otherwise
      offenders.each do |offender|
        create(:case_information, offender: build(:offender, nomis_offender_id: offender.fetch(:prisonerNumber)))
        alloc = create(:allocation_history, nomis_offender_id: offender.fetch(:prisonerNumber), primary_pom_nomis_id: pom.staffId, prison: prison.code)
        alloc.update!(primary_pom_nomis_id: pom.staffId,
                      event: AllocationHistory::REALLOCATE_PRIMARY_POM,
                      event_trigger: AllocationHistory::USER)
      end
    end

    context 'when a womens prison' do
      before do
        stub_sso_data(prison.code)
      end

      describe '#index' do
        let(:prison) { create(:womens_prison) }

        it 'can sort by complexity' do
          get :index, params: { prison_id: prison.code, staff_id: staff_id, sort: 'complexity_level_number asc' }
          expect(response).to be_successful
          expect(assigns(:allocations).map(&:complexity_level)).to eq ['low', 'medium', 'high']
        end

        it 'can sort by complexity desc' do
          get :index, params: { prison_id: prison.code, staff_id: staff_id, sort: 'complexity_level_number desc' }
          expect(response).to be_successful
          expect(assigns(:allocations).map(&:complexity_level)).to eq ['high', 'medium', 'low']
        end
      end
    end

    context 'when a mens prison' do
      let(:prison) { create(:prison) }

      describe '#index' do
        context 'when user is an SPO' do
          before do
            stub_sso_data(prison.code)
          end

          it 'is allowed' do
            get :index, params: { prison_id: prison.code, staff_id: staff_id }
            expect(response).to be_successful
          end
        end

        context 'when user is a different POM to the one signed in' do
          before do
            stub_signed_in_pom(prison.code, staff_id, 'alice')
          end

          it 'cant see the caseload' do
            get :index, params: { prison_id: prison.code, staff_id: not_signed_in }
            expect(response).to redirect_to('/401')
          end
        end

        context 'when user is the signed in POM' do
          before do
            stub_signed_in_pom(prison.code, staff_id, 'alice')
          end

          let(:allocations) { assigns(:allocations).index_by(&:nomis_offender_id) }

          before do
            get :index, params: { prison_id: prison.code, staff_id: staff_id }
          end

          it 'is allowed' do
            expect(response).to be_successful
          end

          it 'returns the caseload' do
            expect(assigns(:allocations).map(&:nomis_offender_id)).to match_array(offenders.map { |o| o.fetch(:prisonerNumber) })
          end

          it 'returns ROTL information' do
            expect(offenders.map { |o| allocations.fetch(o.fetch(:prisonerNumber)).latest_temp_movement_date }).to eq [today, nil, nil]
          end
        end
      end

      describe '#new_cases' do
        before do
          stub_sso_data(prison.code)
        end

        it 'returns the caseload' do
          get :new_cases, params: { prison_id: prison.code, staff_id: staff_id }
          expect(response).to be_successful

          expect(assigns(:new_cases).map(&:nomis_offender_id)).to match_array(offenders.map { |o| o.fetch(:prisonerNumber) })
        end
      end
    end
  end
end
