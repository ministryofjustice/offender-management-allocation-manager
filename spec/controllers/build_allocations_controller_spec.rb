RSpec.describe BuildAllocationsController, type: :controller do
  let(:poms) { [build(:pom, :prison_officer), build(:pom, :prison_officer)] }
  let(:pom) { poms.first }
  let(:prison) { create(:prison) }
  let(:offender) { build(:nomis_offender, prisonId: prison.code) }
  let(:offender_no) { offender.fetch(:prisonerNumber) }

  before do
    stub_poms(prison.code, poms)
    stub_signed_in_pom(prison.code, pom.staffId, 'Alice')
    stub_sso_data(prison.code)
    stub_offender(offender)
    create(:case_information, offender: build(:offender, nomis_offender_id: offender_no))
    stub_community_offender(offender_no, build(:community_data))
    allow_any_instance_of(StaffMember).to receive(:first_name).and_return('Bob')
    allow_any_instance_of(StaffMember).to receive(:last_name).and_return('Billings')

    allow(EmailService).to receive(:send_email)
  end

  describe '#new' do
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
          id: 'allocate'
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
          "prison_id" => prison.code,
          "prisoner_id" => offender_no,
          "staff_id" => pom.staffId,
          "id" => "allocate"
        }
      end

      it 'returns success' do
        expect(response.code).to eq('200')
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
          "prison_id" => prison.code,
          "prisoner_id" => offender_no,
          "staff_id" => pom_nomis_id,
          "id" => "allocate"
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
          expect(response.code).to eq('200')
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

    context 'when submitting the override step without any reasons selected' do
      before do
        put :update, params: {
          prison_id: prison.code,
          prisoner_id: offender_no,
          staff_id: pom.staffId,
          id: 'override',
          override_form: {
            override_reasons: [''],
            more_detail: '',
            suitability_detail: ''
          }
        }
      end

      it 're-renders the override step successfully' do
        expect(response).to have_http_status(:ok)
        expect(assigns(:pom)).to be_present
        expect(assigns(:override).errors[:override_reasons]).to include('Select one or more reasons for not accepting the recommendation')
      end
    end

    context 'when allocating' do
      before do
        stub_user('user', pom.staffId)

        put :update, params: {
          allocation_form: { message: notes },
          prison_id: prison.code,
          prisoner_id: offender_no,
          staff_id: pom.staffId,
          id: 'allocate'
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

      it 'stores no message in flash notice' do
        expect(flash[:notice]).to be_nil
      end

      it 'adds additional notes to stored allocation details' do
        expect(session[:latest_allocation_details]).to include(
          prisoner_number: offender_no,
          additional_notes: notes
        )
      end

      it 'redirects to Make allocations' do
        expect(response).to redirect_to(unallocated_prison_prisoners_path)
      end
    end

    context 'when re-allocating' do
      before do
        create(:allocation_history, prison: prison.code, nomis_offender_id: offender_no,
                                    primary_pom_nomis_id: pom_nomis_id)
      end

      context 'with the same POM' do
        before do
          allow(AllocationService).to receive(:create_or_update).and_return(nil)
          session[:latest_allocation_details] = { prisoner_number: 'STALE123' }
          session[:allocation_override] = { override_reasons: ['x'] }

          put :update, params: {
            prison_id: prison.code,
            prisoner_id: offender_no,
            staff_id: pom.staffId,
            id: 'allocate'
          }
        end

        let(:pom_nomis_id) { pom.staffId }

        it 'does not call AllocationService.create_or_update' do
          expect(AllocationService).not_to have_received(:create_or_update)
        end

        it 'redirects back to choose a POM with an alert' do
          expect(response).to redirect_to(prison_prisoner_staff_index_path(prison.code, offender_no))
          expect(flash[:alert]).to eq('Choose a POM from the available list to allocate this case.')
          expect(flash[:notice]).to be_nil
        end

        it 'clears wizard state and does not store offender details' do
          expect(session).not_to have_key(:latest_allocation_details)
          expect(session).not_to have_key(:allocation_override)
        end
      end

      context 'with a different POM' do
        before do
          stub_user('user', pom.staffId)
          allow(AllocationService).to receive(:create_or_update).and_call_original

          put :update, params: {
            allocation_form: { message: notes },
            prison_id: prison.code,
            prisoner_id: offender_no,
            staff_id: pom.staffId,
            id: 'allocate'
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

        it 'stores no message in flash notice' do
          expect(flash[:notice]).to be_nil
        end

        it 'adds additional notes to stored allocation details' do
          expect(session[:latest_allocation_details]).to include(
            prisoner_number: offender_no,
            prev_pom_name: 'Bob Billings',
            additional_notes: notes
          )
        end

        it 'redirects to See allocations' do
          expect(response).to redirect_to(allocated_prison_prisoners_path)
        end

        it 'stores nil override reasons when no override was provided' do
          expect(AllocationService).to have_received(:create_or_update) do |attributes, _further_info|
            expect(attributes[:override_reasons]).to be_nil
          end
        end
      end
    end
  end
end
