RSpec.describe BuildAllocationsController, type: :controller do
  let(:poms) { [build(:pom, :prison_officer), build(:pom, :prison_officer)] }
  let(:pom) { poms.first }
  let(:prison) { create(:prison) }
  let(:offender) { build(:nomis_offender, prisonId: prison.code) }
  let(:offender_no) { offender.fetch(:prisonerNumber) }

  before do
    allow_any_instance_of(DomainEvents::Event).to receive(:publish).and_return(nil)
    stub_poms(prison.code, poms)
    stub_signed_in_pom(prison.code, pom.staffId, 'Alice')
    stub_sso_data(prison.code)
    stub_offender(offender)
    create(:case_information, offender: build(:offender, nomis_offender_id: offender_no))
    stub_community_offender(offender_no, build(:community_data))
    allow_any_instance_of(StaffMember).to receive(:first_name).and_return('Bob')
    allow_any_instance_of(StaffMember).to receive(:last_name).and_return('Billings')
    allow_any_instance_of(MpcOffender).to receive(:rosh_summary).and_return({ status: :missing })

    allow(EmailService).to receive(:send_email)
  end

  describe '#show' do
    context 'when allocating' do
      before do
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

      it 'stores offender details' do
        expect(session).to have_key(:latest_allocation_details)
        expect(session[:latest_allocation_details]).to include(prisoner_number: offender_no)
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

        it 'returns success' do
          expect(response.code).to eq('200')
        end

        it 'does not store offender details' do
          expect(session).not_to have_key(:latest_allocation_details)
        end
      end

      context 'with a different POM' do
        let(:pom_nomis_id) { pom.staffId + 123 }

        it 'returns success' do
          expect(response.code).to eq('200')
        end

        it 'stores offender details' do
          expect(session).to have_key(:latest_allocation_details)
          expect(session[:latest_allocation_details]).to include(prisoner_number: offender_no)
        end
      end
    end
  end

  describe '#update' do
    # Tried making this a let but the `put :update` added
    # :additional_notes to it. The code adds this to the session as
    # part of the update, so it may be due to some odd interaction
    # between rspec and sessions. It's a mystery. Using a method rather
    # than a let gets round this issue.
    def further_info
      {
        last_oasys_completed: '23-Jul-2009',
        handover_start_date: '12-Aug-2010',
        handover_completion_date: '13-Sep-2011',
        com_name: 'Billy Smart',
        com_email: 'billy@smart.com'
      }
    end

    let(:notes) { 'A note' }

    context 'when allocating' do
      before do
        session[:latest_allocation_details] = further_info

        put :update, params: {
          allocation_form: { message: notes },
          prison_id: prison.code,
          prisoner_id: offender_no,
          staff_id: pom.staffId,
          id: 'allocate'
        }
      end

      it 'sends the correct emails' do
        expect(EmailService).to have_received(:send_email).with(
          message: notes,
          allocation: anything,
          pom_nomis_id: pom.staffId,
          further_info: further_info,
        )
      end

      it 'stores no message in flash notice' do
        expect(flash[:notice]).to be_nil
      end

      it 'adds additional notes to stored allocation details' do
        expect(session[:latest_allocation_details]).to include(additional_notes: notes)
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

        it 'stores message in flash notice' do
          expect(flash[:notice]).to match(/allocated to/)
        end

        it 'does not store offender details' do
          expect(session).not_to have_key(:latest_allocation_details)
        end

        it 'redirects to See allocations' do
          expect(response).to redirect_to(allocated_prison_prisoners_path)
        end
      end

      context 'with a different POM' do
        before do
          session[:latest_allocation_details] = further_info

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
          expect(EmailService).to have_received(:send_email).with(
            message: notes,
            allocation: anything,
            pom_nomis_id: pom.staffId,
            further_info: further_info,
          )
        end

        it 'stores no message in flash notice' do
          expect(flash[:notice]).to be_nil
        end

        it 'adds additional notes to stored allocation details' do
          expect(session[:latest_allocation_details]).to include(additional_notes: notes)
        end

        it 'redirects to See allocations' do
          expect(response).to redirect_to(allocated_prison_prisoners_path)
        end
      end
    end
  end
end
