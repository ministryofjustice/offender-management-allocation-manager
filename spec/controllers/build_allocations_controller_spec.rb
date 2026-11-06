RSpec.describe BuildAllocationsController, type: :controller do
  include_context 'with HMPPS audit event capture'

  let(:poms) { [build(:pom, :prison_officer), build(:pom, :prison_officer)] }
  let(:pom) { poms.first }
  let(:prison) { create(:prison) }
  let(:offender) { build(:nomis_offender, prisonId: prison.code) }
  let(:offender_no) { offender.fetch(:prisonerNumber) }
  let(:override_session_key) { "allocation_override:#{prison.code}:#{offender_no}:#{pom.staffId}" }
  let(:other_override_keys) do
    [
      "allocation_override:OTHER:#{offender_no}:#{pom.staffId}",
      "allocation_override:#{prison.code}:OTHER123:#{pom.staffId}",
      "allocation_override:#{prison.code}:#{offender_no}:#{poms.last.staffId}",
    ]
  end

  before do
    stub_onboarded_poms(prison, poms)
    stub_signed_in_pom(prison.code, pom.staffId, 'Alice')
    stub_sso_data(prison.code)
    stub_offender(offender)
    create(:case_information, rosh_level: 'HIGH', offender: build(:offender, nomis_offender_id: offender_no))
    stub_community_offender(offender_no, build(:community_data))
    allow_any_instance_of(StaffMember).to receive(:first_name).and_return('Bob')
    allow_any_instance_of(StaffMember).to receive(:last_name).and_return('Billings')

    allow(EmailService).to receive(:send_email)
  end

  describe '#new' do
    it 'resets only the current journey answers' do
      session[override_session_key] = { override_reasons: ['continuity'] }
      other_override_keys.each { |key| session[key] = { 'override_reasons' => ['continuity'] } }

      get :new, params: { prison_id: prison.code, prisoner_id: offender_no, staff_id: pom.staffId }

      expect(session[override_session_key]['override_reasons']).to be_empty
      other_override_keys.each { |key| expect(session[key]).to include('override_reasons' => ['continuity']) }
    end

    context 'when the prisoner cannot be loaded' do
      before do
        stub_non_existent_offender(offender_no)

        get :new, params: {
          prison_id: prison.code,
          prisoner_id: offender_no,
          staff_id: pom.staffId
        }
      end

      it 'redirects to 404' do
        expect(response).to redirect_to('/404')
        expect(hmpps_audit_events).to be_empty
      end
    end

    context 'when the selected POM is no longer eligible' do
      before do
        create(:allocation_history, prison: prison.code, nomis_offender_id: offender_no,
                                    primary_pom_nomis_id: pom.staffId)

        get :new, params: {
          prison_id: prison.code,
          prisoner_id: offender_no,
          staff_id: pom.staffId
        }
      end

      it 'redirects back to choose a POM with an alert' do
        expect(response).to redirect_to(prison_prisoner_staff_index_path(prison.code, offender_no))
        expect(flash[:alert]).to eq('Choose a POM from the available list to allocate this case.')
      end
    end
  end

  describe '#override' do
    it 'loads saved answers without retaining a stale success banner and audits the form' do
      session[override_session_key] = { override_reasons: ['continuity'] }
      session[:latest_allocation_details] = { prisoner_number: 'STALE123' }

      get :override, params: { prison_id: prison.code, prisoner_id: offender_no, staff_id: pom.staffId }

      expect(assigns(:override).override_reasons).to eq(['continuity'])
      expect(session).not_to have_key(:latest_allocation_details)
      expect(hmpps_audit_events).to have_recorded_event(
        'VIEW_NEW_ALLOCATION_OVERRIDE_FORM', subject_type: 'PRISONER_ID', subject_id: offender_no,
                                             details: { 'prisonId' => prison.code, 'queryParams' => { 'staffId' => pom.staffId.to_s } }
      )
    end
  end

  describe '#update_override' do
    it 're-renders invalid answers with 422 without allocating, auditing, or replacing saved answers' do
      session[override_session_key] = { 'override_reasons' => ['continuity'] }
      allow(AllocationService).to receive(:create_or_update)

      put :update_override, params: {
        prison_id: prison.code,
        prisoner_id: offender_no,
        staff_id: pom.staffId,
        override_form: { override_reasons: [''], more_detail: '', suitability_detail: '' }
      }

      expect(response).to have_http_status(:unprocessable_entity)
      expect(assigns(:override).errors[:override_reasons]).to be_present
      expect(session[override_session_key]).to eq('override_reasons' => ['continuity'])
      expect(AllocationService).not_to have_received(:create_or_update)
      expect(hmpps_audit_events).to be_empty
    end

    it 'keeps answers separate when switching between two POM journeys' do
      [pom, poms.last].each_with_index do |selected_pom, index|
        put :update_override, params: {
          prison_id: prison.code,
          prisoner_id: offender_no,
          staff_id: selected_pom.staffId,
          override_form: { override_reasons: ['other'], more_detail: "Reason #{index}" }
        }
      end

      get :override, params: { prison_id: prison.code, prisoner_id: offender_no, staff_id: pom.staffId }
      expect(assigns(:override).more_detail).to eq('Reason 0')

      get :override, params: { prison_id: prison.code, prisoner_id: offender_no, staff_id: poms.last.staffId }
      expect(assigns(:override).more_detail).to eq('Reason 1')
    end

    it 'stores valid answers and redirects to confirmation without allocating or auditing' do
      expect {
        put :update_override, params: {
          prison_id: prison.code,
          prisoner_id: offender_no,
          staff_id: pom.staffId,
          override_form: { override_reasons: ['other'], more_detail: 'A reason' }
        }
      }.not_to change(AllocationHistory, :count)

      expect(session[override_session_key]).to include('override_reasons' => ['other'], 'more_detail' => 'A reason')
      expect(response).to redirect_to(allocate_prison_prisoner_staff_build_allocations_path(prison.code, offender_no, pom.staffId))
      expect(hmpps_audit_events).to be_empty
    end
  end

  describe '#show' do
    context 'when the selected POM is no longer eligible' do
      before do
        create(:allocation_history, prison: prison.code, nomis_offender_id: offender_no,
                                    primary_pom_nomis_id: pom.staffId,
                                    secondary_pom_nomis_id: poms.last.staffId)

        get :show, params: {
          prison_id: prison.code,
          prisoner_id: offender_no,
          staff_id: poms.last.staffId,
        }
      end

      it 'redirects back to choose a POM with an alert' do
        expect(response).to redirect_to(prison_prisoner_staff_index_path(prison.code, offender_no))
        expect(flash[:alert]).to eq('Choose a POM from the available list to allocate this case.')
      end

      it 'does not store offender details' do
        expect(session).not_to have_key(:latest_allocation_details)
      end
    end

    context 'when allocating' do
      before do
        session[:latest_allocation_details] = { prisoner_number: 'STALE123' }

        get :show, params: {
          prison_id: prison.code,
          prisoner_id: offender_no,
          staff_id: pom.staffId,
        }
      end

      it 'returns success' do
        expect(response).to have_http_status(:ok)
        expect(hmpps_audit_events).to have_recorded_event(
          'VIEW_PRIMARY_POM_ALLOCATION_FORM', subject_type: 'PRISONER_ID', subject_id: offender_no,
                                              details: { 'prisonId' => prison.code, 'queryParams' => { 'staffId' => pom.staffId.to_s } }
        )
      end

      it 'stores offender details in an instance variable only' do
        expect(assigns(:latest_allocation_details)).to include(prisoner_number: offender_no)
        expect(session).not_to have_key(:latest_allocation_details)
      end
    end

    context 'when re-allocating' do
      before do
        create(:allocation_history, prison: prison.code, nomis_offender_id: offender_no,
                                    primary_pom_nomis_id: pom.staffId)

        get :show, params: {
          prison_id: prison.code,
          prisoner_id: offender_no,
          staff_id: pom_nomis_id,
        }
      end

      context 'with the same POM' do
        let(:pom_nomis_id) { pom.staffId }

        it 'redirects back to choose a POM with an alert' do
          expect(response).to redirect_to(prison_prisoner_staff_index_path(prison.code, offender_no))
          expect(flash[:alert]).to eq('Choose a POM from the available list to allocate this case.')
        end

        it 'does not store offender details' do
          expect(session).not_to have_key(:latest_allocation_details)
        end
      end

      context 'with a different POM' do
        let(:pom_nomis_id) { poms.last.staffId }

        it 'returns success' do
          expect(response).to have_http_status(:ok)
        end

        it 'stores offender details in an instance variable only' do
          expect(assigns(:latest_allocation_details)).to include(prisoner_number: offender_no)
          expect(session).not_to have_key(:latest_allocation_details)
        end
      end
    end
  end

  describe '#update' do
    def stored_further_info
      session[:latest_allocation_details].slice(
        :last_oasys_completed,
        :handover_start_date,
        :handover_completion_date,
        :com_name,
        :com_email
      )
    end

    let(:notes) { 'A note' }

    context 'when an override is required at final submission' do
      before do
        allow(RecommendationService).to receive(:recommended_pom_type).and_return(RecommendationService::PROBATION_POM)
        allow(AllocationService).to receive(:create_or_update)
        session[:latest_allocation_details] = { prisoner_number: 'STALE123' }
      end

      {
        'missing answers' => nil,
        'empty reasons' => { 'override_reasons' => [] },
        'missing required explanation' => { 'override_reasons' => ['other'], 'more_detail' => '' },
      }.each do |description, answers|
        it "rejects #{description} without allocating" do
          session[override_session_key] = answers

          put :update, params: {
            allocation_form: { message: notes },
            prison_id: prison.code,
            prisoner_id: offender_no,
            staff_id: pom.staffId,
          }

          expect(response).to redirect_to(override_prison_prisoner_staff_build_allocations_path(prison.code, offender_no, pom.staffId))
          expect(AllocationService).not_to have_received(:create_or_update)
          expect(EmailService).not_to have_received(:send_email)
          expect(session).not_to have_key(:latest_allocation_details)
          expect(hmpps_audit_events).to have_recorded_event('CREATE_PRIMARY_POM_ALLOCATION', outcome: 'FAILURE', subject_id: offender_no)
          expect(hmpps_audit_events.last[:details]).to include('failureReason' => HmppsAuditing::VALIDATION_FAILED)
        end
      end

      it 'allows completion after the user re-enters valid reasons' do
        stub_user('user', pom.staffId)
        allow(AllocationService).to receive(:create_or_update).and_call_original

        put :update_override, params: {
          prison_id: prison.code,
          prisoner_id: offender_no,
          staff_id: pom.staffId,
          override_form: { override_reasons: ['other'], more_detail: 'Continuity of care' },
        }

        put :update, params: {
          allocation_form: { message: notes },
          prison_id: prison.code,
          prisoner_id: offender_no,
          staff_id: pom.staffId,
        }

        allocation = AllocationHistory.find_by!(nomis_offender_id: offender_no)
        expect(allocation.override_detail).to eq('Continuity of care')
        expect(response).to redirect_to(unallocated_prison_prisoners_path(prison.code))
        expect(session).not_to have_key(override_session_key)
        expect(hmpps_audit_events).to have_recorded_event('CREATE_PRIMARY_POM_ALLOCATION', subject_id: offender_no)
      end
    end

    context 'when the allocation service fails before saving' do
      it 'retains the answers for retry, does not show success, and audits failure' do
        session[override_session_key] = { 'override_reasons' => ['continuity'] }
        allow(AllocationService).to receive(:create_or_update).and_raise('Allocation failed')

        expect {
          put :update, params: {
            allocation_form: { message: notes },
            prison_id: prison.code,
            prisoner_id: offender_no,
            staff_id: pom.staffId,
          }
        }.to raise_error(RuntimeError, 'Allocation failed')

        expect(session[override_session_key]).to eq('override_reasons' => ['continuity'])
        expect(session).not_to have_key(:latest_allocation_details)
        expect(AllocationHistory.find_by(nomis_offender_id: offender_no)).to be_nil
        expect(hmpps_audit_events).to have_recorded_event('CREATE_PRIMARY_POM_ALLOCATION', outcome: 'FAILURE', subject_id: offender_no)
      end
    end

    context 'when allocating' do
      before do
        stub_user('user', pom.staffId)
        session[override_session_key] = { override_reasons: ['continuity'] }
        other_override_keys.each { |key| session[key] = { 'override_reasons' => ['other'], 'more_detail' => 'Another journey' } }

        put :update, params: {
          allocation_form: { message: notes },
          prison_id: prison.code,
          prisoner_id: offender_no,
          staff_id: pom.staffId,
        }
      end

      it 'sends the correct emails' do
        expect(EmailService).to have_received(:send_email) do |args|
          expect(args[:message]).to eq(notes)
          expect(args[:allocation]).to be_present
          expect(args[:pom_nomis_id]).to eq(pom.staffId)
          expect(args[:further_info]).to eq(stored_further_info)
        end
      end

      it 'adds additional notes to stored allocation details' do
        expect(flash[:notice]).to be_nil
        expect(session[:latest_allocation_details]).to include(
          prisoner_number: offender_no,
          additional_notes: notes
        )
      end

      it 'redirects to Make allocations' do
        expect(response).to redirect_to(unallocated_prison_prisoners_path)
        expect(hmpps_audit_events).to have_recorded_event(
          'CREATE_PRIMARY_POM_ALLOCATION', subject_type: 'PRISONER_ID', subject_id: offender_no,
                                           details: { 'prisonId' => prison.code, 'queryParams' => { 'staffId' => pom.staffId.to_s } }
        )
      end

      it 'stores the offender ROSH' do
        allocation = AllocationHistory.find_by!(nomis_offender_id: offender_no)

        expect(allocation.allocated_at_rosh).to eq('HIGH')
      end

      it 'uses and clears only the current journey answers' do
        allocation = AllocationHistory.find_by!(nomis_offender_id: offender_no)
        expect(allocation.override_reasons).to include('continuity')
        expect(allocation.override_detail).to be_nil
        expect(session).not_to have_key(override_session_key)
        other_override_keys.each { |key| expect(session[key]).to include('more_detail' => 'Another journey') }
      end
    end

    context 'when RoSH is missing and tier is not A' do
      before do
        CaseInformation.find_by(nomis_offender_id: offender_no).update!(rosh_level: nil, tier: 'B')
      end

      it 'requires the override step' do
        get :new, params: {
          prison_id: prison.code,
          prisoner_id: offender_no,
          staff_id: pom.staffId
        }

        expect(response).to redirect_to(
          override_prison_prisoner_staff_build_allocations_path(prison.code, offender_no, pom.staffId)
        )
      end

      it 'stores nil recommended_pom_type' do
        stub_user('user', pom.staffId)
        session[override_session_key] = { override_reasons: ['suitability'], suitability_detail: 'Reason given' }

        put :update, params: {
          allocation_form: { message: notes },
          prison_id: prison.code,
          prisoner_id: offender_no,
          staff_id: pom.staffId,
        }

        allocation = AllocationHistory.find_by!(nomis_offender_id: offender_no)
        expect(allocation.recommended_pom_type).to be_nil
      end
    end

    context 'when re-allocating' do
      before do
        allow(RecommendationService).to receive(:recommended_pom_type).and_return(RecommendationService::PRISON_POM)
        create(:allocation_history, prison: prison.code, nomis_offender_id: offender_no,
                                    primary_pom_nomis_id: pom_nomis_id)
      end

      context 'with the same POM' do
        before do
          allow(AllocationService).to receive(:create_or_update).and_return(nil)
          session[:latest_allocation_details] = { prisoner_number: 'STALE123' }
          session[override_session_key] = { override_reasons: ['x'] }
          other_override_keys.each { |key| session[key] = { 'override_reasons' => ['continuity'] } }

          put :update, params: {
            prison_id: prison.code,
            prisoner_id: offender_no,
            staff_id: pom.staffId,
          }
        end

        let(:pom_nomis_id) { pom.staffId }

        it 'does not call AllocationService.create_or_update' do
          expect(AllocationService).not_to have_received(:create_or_update)
          expect(hmpps_audit_events).to have_recorded_event('CREATE_PRIMARY_POM_ALLOCATION', outcome: 'FAILURE', subject_id: offender_no)
        end

        it 'redirects back to choose a POM with an alert' do
          expect(response).to redirect_to(prison_prisoner_staff_index_path(prison.code, offender_no))
          expect(flash[:alert]).to eq('Choose a POM from the available list to allocate this case.')
          expect(flash[:notice]).to be_nil
        end

        it 'clears only the rejected journey answers and the success banner' do
          expect(session).not_to have_key(:latest_allocation_details)
          expect(session).not_to have_key(override_session_key)
          other_override_keys.each { |key| expect(session[key]).to include('override_reasons' => ['continuity']) }
        end
      end

      context 'with a different POM' do
        before do
          stub_user('user', pom.staffId)
          put :update, params: {
            allocation_form: { message: notes },
            prison_id: prison.code,
            prisoner_id: offender_no,
            staff_id: pom.staffId,
          }
        end

        let(:pom_nomis_id) { poms.last.staffId }

        it 'sends the correct emails' do
          expect(EmailService).to have_received(:send_email) do |args|
            expect(args[:message]).to eq(notes)
            expect(args[:allocation]).to be_present
            expect(args[:pom_nomis_id]).to eq(pom.staffId)
            expect(args[:further_info]).to eq(stored_further_info)
          end
        end

        it 'adds additional notes to stored allocation details' do
          expect(flash[:notice]).to be_nil
          expect(session[:latest_allocation_details]).to include(
            prisoner_number: offender_no,
            prev_pom_name: 'Bob Billings',
            additional_notes: notes
          )
        end

        it 'redirects to See allocations' do
          expect(response).to redirect_to(allocated_prison_prisoners_path)
          expect(hmpps_audit_events).to have_recorded_event('CREATE_PRIMARY_POM_ALLOCATION', subject_id: offender_no)
        end

        it 'stores nil override reasons when no override was provided' do
          allocation = AllocationHistory.find_by!(nomis_offender_id: offender_no)
          expect(allocation.override_reasons).to be_nil
        end

        it 'stores the offender ROSH' do
          allocation = AllocationHistory.find_by!(nomis_offender_id: offender_no)

          expect(allocation.allocated_at_rosh).to eq('HIGH')
        end
      end

      context 'with a different POM when the journey started from Review allocations' do
        let(:pom_nomis_id) { poms.last.staffId }

        before do
          stub_user('user', pom.staffId)
          session[JourneyReturn::SESSION_KEY] = {
            "allocation:#{prison.code}:#{offender_no}" => {
              'source' => 'review_allocations', 'expires_at' => JourneyReturn::SOURCE_TTL.from_now.to_i
            }
          }

          put :update, params: {
            allocation_form: { message: notes },
            prison_id: prison.code,
            prisoner_id: offender_no,
            staff_id: pom.staffId,
          }
        end

        it 'redirects back to Review allocations' do
          expect(response).to redirect_to(review_allocations_prison_prisoners_path(prison.code))
        end

        it 'forgets the journey source' do
          expect(session[JourneyReturn::SESSION_KEY]).to be_empty
        end

        it 'keeps the allocation details for the success banner' do
          expect(session[:latest_allocation_details]).to include(prisoner_number: offender_no)
        end
      end
    end
  end
end
