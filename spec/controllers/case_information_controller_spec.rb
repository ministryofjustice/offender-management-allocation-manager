# frozen_string_literal: true

require 'rails_helper'

RSpec.describe CaseInformationController, type: :controller do
  let(:prison) { create(:prison) }
  let(:offender) { build(:nomis_offender, prisonId: prison.code) }
  let(:offender_no) { offender.fetch(:prisonerNumber) }
  let(:pom) { build(:pom) }
  let!(:offender_record) { create(:offender, nomis_offender_id: offender_no) }

  before do
    stub_offender(offender)
    stub_sso_data(prison.code)
    stub_poms(prison.code, [pom])
  end

  describe '#create' do
    it 'creates a new manual-entry case information record' do
      post :create, params: {
        prison_id: prison.code,
        prisoner_id: offender_no,
        commit: 'Save',
        case_information: {
          tier: 'A',
          enhanced_resourcing: 'true'
        }
      }

      case_information = CaseInformation.find_by!(nomis_offender_id: offender_no)

      aggregate_failures do
        expect(response).to redirect_to(missing_information_prison_prisoners_path(prison.code, sort: nil, page: nil))
        expect(case_information.manual_entry?).to be(true)
        expect(case_information.tier).to eq('A')
        expect(case_information.enhanced_resourcing).to be(true)
      end
    end

    it 'redirects to the review-case page when saving and allocating' do
      post :create, params: {
        prison_id: prison.code,
        prisoner_id: offender_no,
        commit: 'Save and allocate',
        case_information: {
          tier: 'A',
          enhanced_resourcing: 'true'
        }
      }

      aggregate_failures do
        expect(response).to redirect_to(prison_prisoner_review_case_details_path(prison_id: prison.code, prisoner_id: offender_no))
        expect(CaseInformation.find_by!(nomis_offender_id: offender_no).manual_entry?).to be(true)
      end
    end

    context 'when case information already exists and is not manual entry' do
      let!(:case_information) do
        create(:case_information,
               offender: offender_record,
               manual_entry: false,
               tier: 'B',
               enhanced_resourcing: false)
      end

      it 'refuses direct create requests and leaves the record unchanged' do
        post :create, params: {
          prison_id: prison.code,
          prisoner_id: offender_no,
          commit: 'Save',
          case_information: {
            tier: 'A',
            enhanced_resourcing: 'true'
          }
        }

        aggregate_failures do
          expect(response).to redirect_to('/404')
          expect(case_information.reload.manual_entry?).to be(false)
          expect(case_information.tier).to eq('B')
          expect(case_information.enhanced_resourcing).to be(false)
        end
      end
    end
  end

  describe '#new' do
    context 'when the offender record does not exist locally' do
      before do
        allow(Offender).to receive(:find_by).with(nomis_offender_id: offender_no).and_return(nil)
      end

      it 'redirects to not found' do
        get :new, params: { prison_id: prison.code, prisoner_id: offender_no }

        expect(response).to redirect_to('/404')
      end
    end

    context 'when case information already exists and is not manual entry' do
      before do
        create(:case_information, offender: offender_record, manual_entry: false)
      end

      it 'refuses direct access to the new page' do
        get :new, params: { prison_id: prison.code, prisoner_id: offender_no }

        expect(response).to redirect_to('/404')
      end
    end
  end

  describe '#update' do
    context 'when case information is a manual entry' do
      let!(:case_information) do
        create(:case_information,
               offender: offender_record,
               manual_entry: true,
               tier: 'B',
               enhanced_resourcing: false)
      end

      it 'redirects back to review case details when from is review_case' do
        put :update, params: {
          prison_id: prison.code,
          prisoner_id: offender_no,
          from: 'review_case',
          case_information: {
            tier: 'A',
            enhanced_resourcing: 'true'
          }
        }

        expect(response).to redirect_to(prison_prisoner_review_case_details_path(prison_id: prison.code, prisoner_id: offender_no))
      end

      it 'redirects back to allocation information when from is allocation' do
        put :update, params: {
          prison_id: prison.code,
          prisoner_id: offender_no,
          from: 'allocation',
          case_information: {
            tier: 'A',
            enhanced_resourcing: 'true'
          }
        }

        expect(response).to redirect_to(prison_prisoner_allocation_path(prison.code, prisoner_id: offender_no))
      end
    end

    context 'when case information already exists and is not manual entry' do
      let!(:case_information) do
        create(:case_information,
               offender: offender_record,
               manual_entry: false,
               tier: 'B',
               enhanced_resourcing: false)
      end

      it 'refuses direct update requests and leaves the record unchanged' do
        put :update, params: {
          prison_id: prison.code,
          prisoner_id: offender_no,
          case_information: {
            tier: 'A',
            enhanced_resourcing: 'true'
          }
        }

        aggregate_failures do
          expect(response).to redirect_to('/404')
          expect(case_information.reload.manual_entry?).to be(false)
          expect(case_information.tier).to eq('B')
          expect(case_information.enhanced_resourcing).to be(false)
        end
      end
    end

    context 'when case information does not exist yet' do
      it 'refuses direct update requests' do
        put :update, params: {
          prison_id: prison.code,
          prisoner_id: offender_no,
          case_information: {
            tier: 'A',
            enhanced_resourcing: 'true'
          }
        }

        expect(response).to redirect_to('/404')
      end
    end
  end
end
