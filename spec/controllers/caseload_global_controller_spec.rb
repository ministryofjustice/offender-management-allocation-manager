# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CaseloadGlobalController, type: :controller do
  let(:staff_id) { 456_987 }
  let(:other_staff_id) { 767_584 }
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
            position: RecommendationService::PRISON_POM),
      build(:pom,
            firstName: 'Helen',
            staffId: other_staff_id,
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
        build(:nomis_offender, :rotl, complexityLevel: 'high', created: 1.day.ago,
                                      sentence: attributes_for(:sentence_detail, automaticReleaseDate: Time.zone.today + 1.week)),
        build(:nomis_offender, complexityLevel: 'medium', created: 1.month.ago),
        build(:nomis_offender, complexityLevel: 'low', created: 2.months.ago),
        build(:nomis_offender, complexityLevel: 'low', created: 2.months.ago),
        build(:nomis_offender, complexityLevel: 'medium', created: 1.month.ago),
        build(:nomis_offender, :rotl, complexityLevel: 'high', created: 1.day.ago),
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
      # include every other offender with another POM
      offenders.each.with_index(1) do |offender, index|
        create(:case_information, offender: build(:offender, nomis_offender_id: offender.fetch(:prisonerNumber)))
        alloc = create(:allocation_history, primary_pom_allocated_at: offender.fetch(:created),
                                            nomis_offender_id: offender.fetch(:prisonerNumber),
                                            primary_pom_nomis_id: pom.staffId, prison: prison.code)
        alloc.update!(primary_pom_nomis_id: index % 2 ? pom.staffId : other_staff_id,
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
          expect(assigns(:all_other_allocations).map(&:complexity_level)).to eq %w[low low medium medium high high]
        end

        it 'can sort by complexity desc' do
          get :index, params: { prison_id: prison.code, staff_id: staff_id, sort: 'complexity_level_number desc' }
          expect(response).to be_successful
          expect(assigns(:all_other_allocations).map(&:complexity_level)).to eq %w[high high medium medium low low]
        end

        it 'indicates offender is high complexity' do
          get :index, params: { prison_id: prison.code, staff_id: staff_id, sort: 'complexity_level_number desc' }
          expect(response).to be_successful
          expect(assigns(:all_other_allocations).first.high_complexity?).to eq true
        end

        it 'indicates offender is not high complexity' do
          get :index, params: { prison_id: prison.code, staff_id: staff_id, sort: 'complexity_level_number desc' }
          expect(response).to be_successful
          expect(assigns(:all_other_allocations).last.high_complexity?).to eq false
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

        describe 'can search by name' do
          it 'can search by name' do
            get :index, params: { prison_id: prison.code, staff_id: staff_id, q: offenders.first.fetch(:prisonerNumber) }
            expect(response).to be_successful
            expect(assigns(:all_other_allocations).map(&:offender_no)).to match_array([offenders.first.fetch(:prisonerNumber)])
          end
        end

        describe 'sorting' do
          it 'can sort by last_name asc' do
            get :index, params: { prison_id: prison.code, staff_id: staff_id, sort: 'last_name asc' }
            expect(response).to be_successful
            expect(assigns(:all_other_allocations).map(&:last_name)).to match_array(offenders.map { |o| o.fetch(:lastName) }.sort)
          end

          it 'can sort by last_name desc' do
            get :index, params: { prison_id: prison.code, staff_id: staff_id, sort: 'last_name desc' }
            expect(response).to be_successful
            expect(assigns(:all_other_allocations).map(&:last_name)).to match_array(offenders.map { |o| o.fetch(:lastName) }.sort.reverse)
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

          let(:all_other_allocations) { assigns(:all_other_allocations).index_by(&:offender_no) }

          it 'is allowed' do
            get :index, params: { prison_id: prison.code, staff_id: staff_id }
            expect(response).to be_successful
          end

          it 'returns all caseloads for prison' do
            get :index, params: { prison_id: prison.code, staff_id: staff_id }
            expect(assigns(:all_other_allocations).map(&:offender_no)).to match_array(offenders.map { |o| o.fetch(:prisonerNumber) })
          end

          it 'returns all caseloads for prison with recent allocations' do
            get :index, params: { f: 'recent_allocations', prison_id: prison.code, staff_id: staff_id }
            expect(assigns(:recent_allocations).map(&:offender_no)).to match_array([offenders.first.fetch(:prisonerNumber), offenders.last.fetch(:prisonerNumber)])
          end

          it 'returns all caseloads for prison with upcoming releases' do
            get :index, params: { f: 'upcoming_releases', prison_id: prison.code, staff_id: staff_id }
            expect(assigns(:upcoming_releases).map(&:offender_no)).to match_array([offenders.first.fetch(:prisonerNumber)])
          end

          it 'returns ROTL information' do
            get :index, params: { prison_id: prison.code, staff_id: staff_id }
            expect(offenders.map { |o| all_other_allocations.fetch(o.fetch(:prisonerNumber)).latest_temp_movement_date }).to eq [today, nil, nil, nil, nil, nil]
          end
        end
      end
    end
  end
end
