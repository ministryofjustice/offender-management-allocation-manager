# frozen_string_literal: true

require 'rails_helper'

RSpec.describe EarlyAllocationsController, type: :controller do
  let(:nomis_staff_id) { 444_555 }

  let(:poms) {
    [
      build(:pom,
            firstName: 'Alice',
            position: RecommendationService::PRISON_POM,
            staffId: nomis_staff_id,
            emails: ['test@digital.justice.org.uk']
      ),
      build(:pom,
            firstName: 'Bob',
            position: RecommendationService::PRISON_POM,
            staffId: 2,
            emails: ['test@digital.justice.org.uk']
      )
    ]
  }

  # any date less than 3 months in the past
  let(:valid_date) { Time.zone.today - 2.months }
  let(:prison) { 'WEI' }
  let(:nomis_offender_id) { 'B44455' }
  let(:s1_boolean_param_names) { [:convicted_under_terrorisom_act_2000, :high_profile, :serious_crime_prevention_order, :mappa_level_3, :cppc_case] }
  let(:s1_boolean_params) { s1_boolean_param_names.map { |p| [p, 'false'] }.to_h }

  before do
    stub_sso_data(prison)

    stub_offender(nomis_offender_id)

    stub_poms(prison, poms)

    create(:allocation, nomis_offender_id: nomis_offender_id, primary_pom_nomis_id: nomis_staff_id)
  end

  context 'with not ldu email address' do
    let(:ldu) { create(:local_divisional_unit, email_address: nil) }

    before do
      create(:case_information, nomis_offender_id: nomis_offender_id, local_divisional_unit: ldu)
    end

    it 'goes to the dead end' do
      get :new, params: { prison_id: prison,
                          prisoner_id: nomis_offender_id }

      assert_template 'dead_end'
    end
  end

  context 'with a good ldu complete with email address' do
    before do
      create(:case_information, nomis_offender_id: nomis_offender_id)
    end

    context 'when stage 1' do
      let(:date_params) {
        { "oasys_risk_assessment_date_dd" => valid_date.day,
          "oasys_risk_assessment_date_mm" => valid_date.month,
          "oasys_risk_assessment_date_yyyy" => valid_date.year
        }
      }

      context 'when any one boolean true' do
        it 'declares assessment complete and eligible' do
          s1_boolean_param_names.each do |field|
            s1_boolean_params[field] = 'true'

            post :create, params: { prison_id: prison,
                                    prisoner_id: nomis_offender_id,
                                    early_allocation: date_params.merge(s1_boolean_params) }
            assert_template('eligible')
          end
        end
      end

      context 'when no booleans true' do
        render_views
        it 'renders the second screen of questions' do
          post :create, params: { prison_id: prison,
                                  prisoner_id: nomis_offender_id,
                                  early_allocation: date_params.merge(s1_boolean_params) }
          expect(response.body).to include('Extremism separation centres')
        end
      end
    end

    context 'when stage 2' do
      let(:s2_boolean_param_names) {
        [:due_for_release_in_less_than_24months,
         :high_risk_of_serious_harm,
         :mappa_level_2,
         :pathfinder_process,
         :other_reason]
      }

      let(:s2_boolean_params) { s2_boolean_param_names.map { |p| [p, 'false'] }.to_h }

      it 'is ineligible if <24 months is false but extremism_separation is true' do
        post :create, params: {
          prison_id: prison,
          prisoner_id: nomis_offender_id,
          early_allocation: {
            oasys_risk_assessment_date: valid_date,
            extremism_separation: true,
            stage2_validation: true
          }.merge(s1_boolean_params).merge(s2_boolean_params)
        }

        assert_template 'ineligible'
      end
    end
  end
end
