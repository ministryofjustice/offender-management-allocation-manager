# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Reallocations::JourneyController, type: :controller do
  render_views

  include_context 'with reallocation controller defaults'

  let(:route_params) do
    {
      prison_id: prison.code,
      nomis_staff_id: old_pom.staffId,
      new_pom: new_pom.staffId
    }
  end

  let(:override_route_params) do
    route_params.merge(nomis_offender_id: override_offender_no)
  end

  shared_context 'with an override case in the reallocation journey' do
    let(:offenders_in_prison) { [offender, override_offender] }
    let(:selected_offender_ids) { [override_offender_no] }
    let(:override_offender_ids) { [override_offender_no] }
    let(:overrides) { {} }

    before do
      create_reallocation_case(override_offender_no, tier: 'C')
      session[:bulk_reallocation] = bulk_reallocation_journey_data(
        selected_offender_ids:,
        override_offender_ids:,
        overrides:
      )
    end
  end

  describe '#override' do
    include_context 'with an override case in the reallocation journey'

    it 'renders the per-case override page' do
      get :override, params: override_route_params

      expect(response).to be_successful
      expect(response.body).to include("Why are you allocating a probation POM to #{override_offender[:firstName]} #{override_offender[:lastName]} (#{override_offender_no})?")
      expect(response.body).to include('Allocate to someone else')
      expect(response.body).to include('Choose all that apply')
    end
  end

  describe '#update_override' do
    include_context 'with an override case in the reallocation journey'

    it 'stores the override and moves to the summary step' do
      put :update_override, params: override_route_params.merge(
        override_form: {
          override_reasons: ['other'],
          more_detail: 'Need continuity'
        }
      )

      expect(response).to redirect_to(summary_prison_reallocation_path(prison, old_pom.staffId, new_pom.staffId))
      expect(session[:bulk_reallocation]['overrides'][override_offender_no]['more_detail']).to eq('Need continuity')
    end

    it 'redirects to the POM list when the last case is excluded' do
      put :update_override, params: override_route_params.merge(allocate_to_someone_else: '1')

      expect(response).to redirect_to(prison_reallocation_path(prison, old_pom.staffId))
      expect(session[:bulk_reallocation]).to be_nil
    end

    context 'when there are other selected cases left in the batch' do
      let(:selected_offender_ids) { [offender_no, override_offender_no] }

      it 'removes the skipped case from the selected batch and continues to summary' do
        put :update_override, params: override_route_params.merge(allocate_to_someone_else: '1')

        expect(response).to redirect_to(summary_prison_reallocation_path(prison, old_pom.staffId, new_pom.staffId))
        expect(session[:bulk_reallocation]['selected_offender_ids']).to eq([offender_no])
        expect(session[:bulk_reallocation]['override_offender_ids']).to be_empty
      end
    end
  end

  describe '#summary' do
    include_context 'with an override case in the reallocation journey'

    let(:selected_offender_ids) { [offender_no, override_offender_no] }
    let(:overrides) do
      {
        override_offender_no => {
          override_reasons: ['other'],
          more_detail: 'Need continuity'
        }
      }
    end

    it 'renders the confirmation page for the selected cases' do
      get :summary, params: route_params

      expect(response).to be_successful
      expect(response.body).to include('Confirm reallocation of 2 cases')
      expect(response.body).to include("#{offender[:lastName]}, #{offender[:firstName]} (#{offender_no})")
      expect(response.body).to include("#{override_offender[:lastName]}, #{override_offender[:firstName]} (#{override_offender_no})")
      expect(response.body).to include('Add a note to the email')
    end
  end

  describe '#complete' do
    include_context 'with an override case in the reallocation journey'

    let(:persisted_allocation) { instance_double(AllocationHistory, primary_pom_nomis_id: new_pom.staffId) }

    let(:selected_offender_ids) { [offender_no, override_offender_no] }
    let(:overrides) do
      {
        override_offender_no => {
          override_reasons: ['other'],
          more_detail: 'Need continuity'
        }
      }
    end

    before do
      allow(AllocationService).to receive(:create_or_update).and_return(persisted_allocation)
      allow(EmailService).to receive(:send_email)
    end

    it 'reallocates the selected cases and redirects to confirmation' do
      put :complete, params: route_params.merge(allocation_form: { message: 'Bulk move' })

      expect(response).to redirect_to(confirmation_prison_reallocation_path(prison.code, old_pom.staffId, new_pom.staffId))
      expect(AllocationService).to have_received(:create_or_update).twice
      expect(session[:bulk_reallocation]).to be_nil
      expect(session[:bulk_reallocation_confirmation][:message]).to eq('Bulk move')
      expect(session[:bulk_reallocation_confirmation][:selected_cases].map { |selected_case| selected_case[:nomis_offender_id] })
        .to eq([offender_no, override_offender_no])
    end

    context 'when a case was skipped during override' do
      let(:selected_offender_ids) { [offender_no] }
      let(:override_offender_ids) { [] }
      let(:overrides) { {} }

      it 'does not include the skipped case in the completion or confirmation payload' do
        put :complete, params: route_params.merge(allocation_form: { message: 'Bulk move' })

        expect(AllocationService).to have_received(:create_or_update).once
        expect(session[:bulk_reallocation_confirmation][:selected_cases].map { |selected_case| selected_case[:nomis_offender_id] })
          .to eq([offender_no])
      end
    end
  end

  describe '#confirmation' do
    let(:remaining_cases_count) { 3 }

    before do
      session[:bulk_reallocation_confirmation] = {
        source_pom_id: old_pom.staffId,
        target_pom_id: new_pom.staffId,
        selected_cases: [
          { full_name: 'Zephyr, Alice', nomis_offender_id: offender_no },
          { full_name: 'Amber, Bob', nomis_offender_id: override_offender_no }
        ],
        message: 'Bulk move',
        remaining_cases_count: remaining_cases_count
      }
    end

    it 'renders the confirmation page with the next-step loop back to select pom' do
      get :confirmation, params: route_params

      expect(response).to be_successful
      expect(response.body).to include('Cases reallocated')
      expect(response.body).to include('Reallocation details')
      expect(response.body).to include('Update sent')
      expect(response.body).to include('What next')
      expect(response.body).to include('Bulk move')
      expect(response.body).to include('Reallocate cases now')
      expect(response.body).to include(prison_reallocation_path(prison.code, old_pom.staffId))
      expect(response.body).to include(prison_poms_path(prison.code))
    end

    context 'when there are no more cases left to reallocate' do
      let(:remaining_cases_count) { 0 }

      it 'renders the no-more-cases copy and omits the loop-back action' do
        get :confirmation, params: route_params

        expect(response).to be_successful
        expect(response.body).to include('Old Pom has no more cases and has been removed from this service.')
        expect(response.body).not_to include('Reallocate cases now')
      end
    end
  end
end
