# frozen_string_literal: true

require 'rails_helper'

RSpec.describe FemaleMissingInfosController, type: :controller do
  let(:prison) { create(:womens_prison) }
  let(:offender) { build(:nomis_offender, prisonId: prison.code, complexityLevel: complexity_level) }
  let(:offender_no) { offender.fetch(:prisonerNumber) }
  let(:pom) { build(:pom) }

  before do
    stub_offender(offender)
    stub_sso_data(prison.code)
    stub_poms(prison.code, [pom])
  end

  describe '#new' do
    context 'when the prisoner already has a complexity level' do
      let(:complexity_level) { 'medium' }

      it 'redirects straight to the shared case information step' do
        get :new, params: { prison_id: prison.code, prisoner_id: offender_no }

        expect(response).to redirect_to(new_prison_prisoner_case_information_path(prison.code, prisoner_id: offender_no, sort: nil, page: nil))
      end
    end
  end

  describe '#update' do
    before do
      allow(HmppsApi::ComplexityApi).to receive(:save)
    end

    context 'when case information is still missing' do
      let(:complexity_level) { nil }

      it 'saves complexity, marks the session, and redirects to case information' do
        put :update, params: {
          prison_id: prison.code,
          prisoner_id: offender_no,
          complexity_form: { complexity_level: 'low' },
          sort: 'last_name',
          page: '2'
        }

        aggregate_failures do
          expect(HmppsApi::ComplexityApi).to have_received(:save).with(
            offender_no,
            level: 'low',
            username: 'user',
            reason: nil
          )
          expect(session["female_missing_info_complexity_saved_#{offender_no}"]).to eq(true)
          expect(response).to redirect_to(new_prison_prisoner_case_information_path(prison.code, prisoner_id: offender_no, sort: 'last_name', page: '2'))
        end
      end
    end

    context 'when case information already exists' do
      let(:complexity_level) { nil }

      before do
        create(:case_information, offender: build(:offender, nomis_offender_id: offender_no))
      end

      it 'redirects to review case details after saving complexity' do
        put :update, params: {
          prison_id: prison.code,
          prisoner_id: offender_no,
          complexity_form: { complexity_level: 'medium' }
        }

        aggregate_failures do
          expect(HmppsApi::ComplexityApi).to have_received(:save).with(
            offender_no,
            level: 'medium',
            username: 'user',
            reason: nil
          )
          expect(response).to redirect_to(prison_prisoner_review_case_details_path(prison_id: prison.code, prisoner_id: offender_no))
        end
      end
    end
  end
end
