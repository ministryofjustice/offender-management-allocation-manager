# frozen_string_literal: true

require 'rails_helper'

RSpec.describe EarlyAllocationsController, type: :controller do
  # any date less than 3 months in the past
  let(:valid_date) { Time.zone.today - 2.months }
  let(:s1_boolean_param_names) { [:convicted_under_terrorisom_act_2000, :high_profile, :serious_crime_prevention_order, :mappa_level_3, :cppc_case] }
  let(:s1_boolean_params) { s1_boolean_param_names.index_with { 'false' } }

  let!(:prison) { create(:prison).code }
  let(:first_pom) { build(:pom) }
  let(:nomis_staff_id) { first_pom.staffId }

  let(:poms) do
    [
      first_pom,
      build(:pom)
    ]
  end

  let(:offender) { build(:nomis_offender, prisonId: prison, sentence: attributes_for(:sentence_detail, sentenceStartDate: Time.zone.today - 9.months,  conditionalReleaseDate: release_date)) }
  let!(:db_offender) { Offender.find_or_create_by!(nomis_offender_id: nomis_offender_id) }
  let!(:case_info) { create(:case_information, offender: db_offender) }
  let(:nomis_offender_id) { offender.fetch(:prisonerNumber) }
  let(:mpc_offender) { OffenderService.get_offender(nomis_offender_id) }

  before do
    stub_signed_in_pom(prison, first_pom.staffId)
    stub_pom(first_pom)

    stub_offender(offender)
    mpc_offender # Use above API stubs to return a valid MpcOffender for let(:mpc_offender)
    allow(OffenderService).to receive(:get_offender).and_raise(NotImplementedError)
    allow(OffenderService).to receive(:get_offender).with(nomis_offender_id).and_return(mpc_offender)

    stub_poms(prison, poms)
    stub_offenders_for_prison(prison, [offender])
    allow(EarlyAllocationService).to receive(:process_eligibility_change)
    create(:allocation_history, prison: prison, nomis_offender_id: nomis_offender_id, primary_pom_nomis_id: nomis_staff_id)
  end

  context 'with some assessments' do
    let!(:early_allocations) do
      # Create 5 Early Allocation records with different creation dates
      [
        create(:early_allocation, offender: case_info.offender, created_at: 1.year.ago),
        create(:early_allocation, offender: case_info.offender, created_at: 6.months.ago),
        create(:early_allocation, offender: case_info.offender, created_at: 1.month.ago),
        create(:early_allocation, offender: case_info.offender, created_at: 1.week.ago),
        create(:early_allocation, offender: case_info.offender, created_at: 1.day.ago)
      ]
    end
    let(:release_date) { Time.zone.today + 17.months }
    let(:early_allocation) { assigns(:early_assignment) }

    before do
      # Create some Early Allocation assessments for a different offender – to prove we don't show them
      create(:offender, early_allocations: build_list(:early_allocation, 5))
    end

    describe '#index' do
      before do
        get :index, params: { prison_id: prison, prisoner_id: nomis_offender_id }
      end

      it 'displays a list of all Early Allocation assessments for the specified offender' do
        assigned_early_allocations = assigns(:early_allocations)
        expect(assigned_early_allocations.size).to eq(5)
        expect(assigned_early_allocations.map(&:nomis_offender_id).uniq).to eq([nomis_offender_id])
      end

      it 'sorts the Early Allocations in descending date order' do
        expected_order = early_allocations.map { |ea| ea.created_at.to_date }.sort.reverse
        actual_order = assigns(:early_allocations).map { |ea| ea.created_at.to_date }
        expect(actual_order).to eq(expected_order)
      end
    end

    describe '#show' do
      [:html, :pdf].each do |format|
        describe "format: #{format}" do
          it 'shows the record specified in :id param' do
            early_allocations.each do |record|
              get :show, params: { prison_id: prison, prisoner_id: nomis_offender_id, id: record.id }, format: format
              expect(assigns(:early_allocation)).to eq(record)
            end
          end

          context 'when the record belongs to a different offender' do
            it 'raises a "Not Found" error' do
              somebody_else = create(:early_allocation)
              expect {
                get :show, params: { prison_id: prison, prisoner_id: nomis_offender_id, id: somebody_else.id }, format: format
              }.to raise_error(ActiveRecord::RecordNotFound)
            end
          end

          context 'when a record with that ID does not exist' do
            it 'raises a "Not Found" error' do
              id = 48_753
              expect {
                get :show, params: { prison_id: prison, prisoner_id: nomis_offender_id, id: id }, format: format
              }.to raise_error(ActiveRecord::RecordNotFound)
            end
          end
        end
      end
    end

    describe '#update' do
      let(:early_allocation) { assigns(:early_allocation) }
      let(:early_allocation_datum) { CalculatedEarlyAllocationStatus.find(nomis_offender_id) }

      it 'updates the updated_by_ fields and processes the eligibility change' do
        put :update, params: { prison_id: prison, prisoner_id: nomis_offender_id, early_allocation: { community_decision: true } }
        aggregate_failures do
          expect(early_allocation.updated_by_firstname).to eq(first_pom.firstName)
          expect(early_allocation.updated_by_lastname).to eq(first_pom.lastName)
          expect(EarlyAllocationService).to have_received(:process_eligibility_change).with(mpc_offender)
        end
      end
    end
  end

  describe '#new' do
    let(:release_date) { Time.zone.today + 17.months }

    context 'with no ldu email address' do
      before do
        mpc_offender.model.case_information.update!(local_delivery_unit: nil)
      end

      it 'goes to the dead end' do
        get :new, params: { prison_id: prison,
                            prisoner_id: nomis_offender_id }

        assert_template 'dead_end'
      end
    end
  end

  describe '#create', :disable_early_allocation_event do
    context 'when on eligible screen' do
      let(:eligible_params) do
        { "oasys_risk_assessment_date" => valid_date,
        }.merge(s1_boolean_params)
      end
      let(:early_allocation) { EarlyAllocation.last }

      context 'when > 18 months from release' do
        let(:release_date) { Time.zone.today + 19.months }

        it 'stores false in created_within_referral_window' do
          post :eligible, params: { prison_id: prison,
                                    prisoner_id: nomis_offender_id,
                                    early_allocation: eligible_params.merge(high_profile: true) }
          assert_template('landing_eligible')
          expect(early_allocation.created_within_referral_window).to eq(false)
        end
      end

      context 'when < 18 months from release' do
        let(:release_date) { Time.zone.today + 17.months }

        context 'when any one boolean true' do
          scenario 'declares assessment complete and eligible' do
            s1_boolean_param_names.each do |field|
              post :eligible, params: { prison_id: prison,
                                        prisoner_id: nomis_offender_id,
                                        early_allocation: eligible_params.merge(field => true) }

              assert_template('landing_eligible')

              expect(early_allocation.prison).to eq(prison)
              expect(early_allocation.created_by_firstname).to eq(first_pom.firstName)
              expect(early_allocation.created_by_lastname).to eq(first_pom.lastName)
              expect(early_allocation.created_within_referral_window).to eq(true)
            end
          end
        end

        context 'when no booleans true' do
          render_views
          it 'renders the second screen of questions' do
            post :eligible, params: { prison_id: prison,
                                      prisoner_id: nomis_offender_id,
                                      early_allocation: eligible_params }
            assert_template('discretionary')
            expect(response.body).to include('Extremism separation centres')
          end
        end
      end
    end

    context 'when stage 2' do
      let(:release_date) { Time.zone.today + 17.months }

      let(:s2_boolean_param_names) do
        [:due_for_release_in_less_than_24months,
         :high_risk_of_serious_harm,
         :mappa_level_2,
         :pathfinder_process,
         :other_reason]
      end

      let(:s2_boolean_params) { s2_boolean_param_names.index_with { |_p| 'false' }.to_h }

      it 'is ineligible if <24 months is false but extremism_separation is true' do
        post :discretionary, params: {
          prison_id: prison,
          prisoner_id: nomis_offender_id,
          early_allocation: {
            oasys_risk_assessment_date: valid_date,
            extremism_separation: true
          }.merge(s1_boolean_params).merge(s2_boolean_params)
        }

        assert_template 'landing_ineligible'
      end
    end
  end

  describe '#edit' do
    let(:release_date) { Time.zone.today + 17.months }
    let(:early_allocation) { create(:early_allocation, nomis_offender_id: nomis_offender_id) }

    it 'renders the edit page' do
      get :edit, params: { prison_id: prison, prisoner_id: nomis_offender_id, id: early_allocation.id }
      assert_template 'edit'
    end
  end

  describe '#oasys_date' do
    let(:release_date) { Time.zone.today + 17.months }

    context 'when form is valid' do
      it 'renders the eligible page' do
        post :oasys_date, params: { prison_id: prison,
                                    prisoner_id: nomis_offender_id,
                                    early_allocation: { oasys_risk_assessment_date: valid_date } }

        assert_template 'eligible'
      end
    end

    context 'when form is invalid' do
      it 'renders the new page' do
        post :oasys_date, params: { prison_id: prison,
                                    prisoner_id: nomis_offender_id,
                                    early_allocation: { oasys_risk_assessment_date: nil } }

        assert_template 'new'
      end
    end
  end
end
