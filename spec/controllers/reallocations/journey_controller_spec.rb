# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Reallocations::JourneyController, type: :controller do
  render_views

  include_context 'with reallocation controller defaults'
  include_context 'with HMPPS audit event capture'

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

  let(:audit_context) do
    { 'prisonId' => prison.code, 'queryParams' => { 'newPom' => new_pom.staffId.to_s } }
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
      expect(hmpps_audit_events).to have_recorded_event('VIEW_NEW_REALLOCATION_OVERRIDE_FORM', who: 'spo-user', subject_type: 'PRISONER_ID', subject_id: override_offender_no)
      expected_details = { 'prisonId' => prison.code, 'queryParams' => { 'nomisStaffId' => old_pom.staffId.to_s, 'newPom' => new_pom.staffId.to_s } }
      expect(hmpps_audit_events.pluck(:details)).to all(eq(expected_details))
    end
  end

  describe '#update_override' do
    include_context 'with an override case in the reallocation journey'

    after do
      expect(hmpps_audit_events).to be_empty
    end

    it 're-renders invalid answers with 422 without changing the saved overrides' do
      saved_journey = session[:bulk_reallocation].deep_dup

      put :update_override, params: override_route_params.merge(
        override_form: { override_reasons: [''] }
      )

      expect(response).to have_http_status(:unprocessable_entity)
      expect(response.body).to include('Select at least one reason')
      expect(session[:bulk_reallocation]).to eq(saved_journey)
    end

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

    it 'renders the summary page successfully' do
      get :summary, params: route_params

      expect(response).to be_successful
      expect(hmpps_audit_events).to have_recorded_event(
        'VIEW_BULK_REALLOCATION_SUMMARY', subject_type: 'USER_ID', subject_id: old_pom.staffId.to_s
      )
      expect(hmpps_audit_events.first[:details]).to eq(audit_context)
      expect(hmpps_audit_events.last[:details]).to eq(
        audit_context.merge('results' => { 'resultCount' => selected_offender_ids.size, 'returnedSubjectIds' => selected_offender_ids })
      )
    end

    it 'audits rejection of a missing journey without reporting prisoner IDs' do
      session.delete(:bulk_reallocation)

      get :summary, params: route_params

      expect(response).to redirect_to(caseload_prison_reallocation_path(prison.code, old_pom.staffId, new_pom.staffId))
      expect(hmpps_audit_events).to have_recorded_event('VIEW_BULK_REALLOCATION_SUMMARY', outcome: 'FAILURE')
      expect(hmpps_audit_events.last[:details]).to eq(
        audit_context.merge('failureReason' => 'Request redirected before completing the operation')
      )
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
      expect(hmpps_audit_events).to have_recorded_event(
        'CREATE_BULK_REALLOCATION', who: 'spo-user', subject_type: 'USER_ID', subject_id: old_pom.staffId.to_s
      )
      expect(hmpps_audit_events.first[:details]).to eq(audit_context)
      expect(hmpps_audit_events.last[:details]).to eq(
        audit_context.merge(
          'selectedPrisonerIds' => selected_offender_ids,
          'reallocatedPrisonerIds' => selected_offender_ids,
          'failedPrisonerIds' => [],
        )
      )
    end

    [false, true].each do |all_fail|
      it "audits #{all_fail ? 'total' : 'partial'} case failure without changing the confirmation flow" do
        allow(AllocationService).to receive(:create_or_update) do |attributes, _context, **|
          raise 'Sensitive exception text' if all_fail || attributes[:nomis_offender_id] == override_offender_no

          persisted_allocation
        end

        put :complete, params: route_params.merge(allocation_form: { message: 'Private note' })

        failed_ids = all_fail ? selected_offender_ids : [override_offender_no]
        successful_ids = all_fail ? [] : [offender_no]
        expect(response).to redirect_to(confirmation_prison_reallocation_path(prison.code, old_pom.staffId, new_pom.staffId))
        expect(hmpps_audit_events).to have_recorded_event('CREATE_BULK_REALLOCATION', outcome: 'FAILURE', subject_id: old_pom.staffId.to_s)
        expect(hmpps_audit_events.last[:details]).to eq(
          audit_context.merge(
            'selectedPrisonerIds' => selected_offender_ids,
            'reallocatedPrisonerIds' => successful_ids,
            'failedPrisonerIds' => failed_ids,
            'failureReason' => 'Some cases failed reallocation',
          )
        )
      end
    end

    it 'retains case results in the failure audit when notifications raise after reallocation' do
      allow_any_instance_of(Reallocation::BulkReallocationNotifier).to receive(:call).and_raise('Notification failed')

      expect {
        put :complete, params: route_params.merge(allocation_form: { message: 'Private note' })
      }.to raise_error(RuntimeError, 'Notification failed')

      expect(hmpps_audit_events).to have_recorded_event('CREATE_BULK_REALLOCATION', outcome: 'FAILURE', subject_id: old_pom.staffId.to_s)
      expect(hmpps_audit_events.last[:details]).to eq(
        audit_context.merge(
          'selectedPrisonerIds' => selected_offender_ids,
          'reallocatedPrisonerIds' => selected_offender_ids,
          'failedPrisonerIds' => [],
          'failureReason' => 'Application failed to complete the operation: RuntimeError',
        )
      )
      expect(session[:bulk_reallocation]).to be_present
    end

    it 'audits rejection of a missing journey without reporting case results' do
      session.delete(:bulk_reallocation)

      put :complete, params: route_params.merge(allocation_form: { message: 'Private note' })

      expect(response).to redirect_to(caseload_prison_reallocation_path(prison.code, old_pom.staffId, new_pom.staffId))
      expect(AllocationService).not_to have_received(:create_or_update)
      expect(hmpps_audit_events).to have_recorded_event('CREATE_BULK_REALLOCATION', outcome: 'FAILURE')
      expect(hmpps_audit_events.last[:details]).to eq(
        audit_context.merge('failureReason' => 'Request redirected before completing the operation')
      )
    end

    context 'when the journey contains only the remaining case after an override skip' do
      let(:selected_offender_ids) { [offender_no] }
      let(:override_offender_ids) { [] }
      let(:overrides) { {} }

      it 'does not include the skipped case in the completion or confirmation payload' do
        put :complete, params: route_params.merge(allocation_form: { message: 'Bulk move' })

        expect(AllocationService).to have_received(:create_or_update).once
        expect(session[:bulk_reallocation_confirmation][:selected_cases].map { |selected_case| selected_case[:nomis_offender_id] })
          .to eq([offender_no])
        expect(hmpps_audit_events.last[:details]).to include(
          'selectedPrisonerIds' => [offender_no],
          'reallocatedPrisonerIds' => [offender_no],
          'failedPrisonerIds' => [],
        )
      end
    end
  end

  describe '#confirmation' do
    context 'when the session contains valid confirmation data' do
      let(:confirmed_cases) do
        [
          { full_name: 'Zephyr, Alice', nomis_offender_id: offender_no, allocated_pom_role: 'Responsible' },
          { full_name: 'Amber, Bob', nomis_offender_id: override_offender_no, allocated_pom_role: 'Supporting' }
        ]
      end
      let(:failed_cases) { [] }

      before do
        session[:bulk_reallocation_confirmation] = {
          source_pom_id: old_pom.staffId,
          target_pom_id: new_pom.staffId,
          message: 'Bulk move',
          selected_cases: confirmed_cases,
          failed_cases:,
          remaining_cases_count: 3,
        }
      end

      it 'renders the confirmation page successfully' do
        get :confirmation, params: route_params

        expect(response).to be_successful
        expect(hmpps_audit_events).to have_recorded_event(
          'VIEW_BULK_REALLOCATION_CONFIRMATION', subject_type: 'USER_ID', subject_id: old_pom.staffId.to_s
        )
        expect(hmpps_audit_events.first[:details]).to eq(audit_context)
        expect(hmpps_audit_events.last[:details]).to eq(
          audit_context.merge(
            'reallocatedPrisonerIds' => [offender_no, override_offender_no],
            'failedPrisonerIds' => [],
          )
        )
      end

      context 'when the confirmation includes a failed reallocation' do
        let(:confirmed_cases) { [super().first] }
        let(:failed_cases) do
          [{ full_name: 'Private name', nomis_offender_id: override_offender_no, error_message: 'Sensitive error' }]
        end

        it 'audits a successful view with both displayed outcome lists' do
          get :confirmation, params: route_params

          expect(response).to be_successful
          expect(hmpps_audit_events).to have_recorded_event('VIEW_BULK_REALLOCATION_CONFIRMATION')
          expect(hmpps_audit_events.last[:details]).to eq(
            audit_context.merge(
              'reallocatedPrisonerIds' => [offender_no],
              'failedPrisonerIds' => [override_offender_no],
            )
          )
        end
      end
    end

    context 'when the session does not contain confirmation data' do
      it 'redirects to the caseload page with an alert' do
        get :confirmation, params: route_params

        expect(response).to redirect_to(caseload_prison_reallocation_path(prison.code, old_pom.staffId, new_pom.staffId))
        expect(flash[:alert]).to eq('Complete a reallocation to view the confirmation page.')
        expect(hmpps_audit_events).to have_recorded_event('VIEW_BULK_REALLOCATION_CONFIRMATION', outcome: 'FAILURE')
        expect(hmpps_audit_events.last[:details]).to eq(
          audit_context.merge('failureReason' => HmppsAuditing::VALIDATION_FAILED)
        )
      end
    end

    context 'when the session confirmation data does not match the route POMs' do
      before do
        session[:bulk_reallocation_confirmation] = {
          source_pom_id: 99_999,
          target_pom_id: 88_888,
          message: '',
          selected_cases: [],
          failed_cases: [],
          remaining_cases_count: 0,
        }
      end

      it 'redirects to the caseload page with an alert' do
        get :confirmation, params: route_params

        expect(response).to redirect_to(caseload_prison_reallocation_path(prison.code, old_pom.staffId, new_pom.staffId))
        expect(flash[:alert]).to eq('Complete a reallocation to view the confirmation page.')
        expect(hmpps_audit_events).to have_recorded_event('VIEW_BULK_REALLOCATION_CONFIRMATION', outcome: 'FAILURE')
        expect(hmpps_audit_events.last[:details]).to eq(
          audit_context.merge('failureReason' => HmppsAuditing::VALIDATION_FAILED)
        )
      end
    end
  end

  describe '#handle_unexpected_error' do
    let(:error) { StandardError.new('something went wrong') }

    before do
      allow(Rails.logger).to receive(:error)
      allow(Rails.error).to receive(:report)
      allow(controller).to receive(:render)

      controller.instance_variable_set(:@prison, prison)
      controller.instance_variable_set(:@pom, double(staff_id: old_pom.staffId))
      controller.instance_variable_set(:@new_pom, double(staff_id: new_pom.staffId))

      controller.send(:handle_unexpected_error, error)
    end

    it 'logs a structured error event' do
      expect(Rails.logger).to have_received(:error).with(
        /event=bulk_reallocation_error.*prison_id=#{prison.code}.*source_pom_id=#{old_pom.staffId}/
      )
    end

    it 'reports to Rails error reporter with context' do
      expect(Rails.error).to have_received(:report).with(
        error,
        severity: :error,
        source: 'bulk_reallocation',
        context: hash_including(
          prison_id: prison.code,
          source_pom_id: old_pom.staffId,
          target_pom_id: new_pom.staffId,
        ),
      )
    end

    it 'renders the error page with 500 status' do
      expect(controller).to have_received(:render).with('reallocations/error', status: :internal_server_error)
    end
  end
end
