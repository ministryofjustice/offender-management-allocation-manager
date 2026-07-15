RSpec.describe HandoverProgressChecklistsController do
  let(:prison) { FactoryBot.create :prison }
  let(:prison_code) { prison.code }
  let(:current_pom) { instance_double(StaffMember, :pom_staff_member, staff_id: 'STAFF1', has_allocation?: false) }
  let(:nomis_offender_id) { FactoryBot.generate :nomis_offender_id }
  let(:default_params) { { prison_id: prison_code, nomis_offender_id: nomis_offender_id } }

  before do
    stub_high_level_pom_auth(prison: prison, staff_member: current_pom)
    allow(current_pom).to receive(:has_allocation?).with(nomis_offender_id).and_return true
    allow(OffenderService).to receive(:get_offender).and_return(nil)
    allow(controller.helpers).to receive(:last_handovers_url).and_return '/last'

    # Ensure the handover gate passes (offender is in handover-in-progress state)
    offender_record = Offender.find_or_create_by!(nomis_offender_id:)
    FactoryBot.create(:calculated_handover_date, :after_handover, offender: offender_record) unless offender_record.calculated_handover_date
  end

  describe '#edit' do
    describe 'when offender exists' do
      let!(:offender) { stub_mpc_offender(offender_no: nomis_offender_id, handover_type: 'enhanced') }

      describe 'when current POM is not the allocated POM' do
        before do
          allow(current_pom).to receive(:has_allocation?).with(nomis_offender_id).and_return false
        end

        it 'responds with unauthorized error' do
          get :edit, params: default_params

          expect(response).to redirect_to('/401')
        end
      end

      it 'assigns the offender' do
        get :edit, params: default_params

        expect(assigns(:offender)).to eq offender
      end

      it 'assigns existing record if that exists' do
        checklist = FactoryBot.create :handover_progress_checklist, nomis_offender_id: nomis_offender_id
        get :edit, params: default_params

        aggregate_failures do
          expect(response.code).to eq '200'
          expect(assigns(:handover_progress_checklist)).to eq checklist
        end
      end

      it 'assigns new record if one does not already exist' do
        get :edit, params: default_params

        record = assigns(:handover_progress_checklist)
        aggregate_failures do
          expect(response.code).to eq '200'
          expect(record.new_record?).to eq true
          expect(record.nomis_offender_id).to eq nomis_offender_id
        end
      end
    end

    describe 'when offender does not exist' do
      it 'shows error' do
        get :edit, params: default_params
        expect(response).to redirect_to('/404')
      end
    end

    describe 'when handover is not in progress or upcoming' do
      let!(:offender) { stub_mpc_offender(offender_no: nomis_offender_id, handover_type: 'enhanced') }

      before do
        # Override the handover date to be POM-only with no upcoming window
        chd = CalculatedHandoverDate.find_by(nomis_offender_id:)
        chd.update!(responsibility: CalculatedHandoverDate::CUSTODY_ONLY, handover_date: 1.year.from_now.to_date)
      end

      it 'responds with unauthorized error' do
        get :edit, params: default_params
        expect(response).to redirect_to('/401')
      end
    end
  end

  describe '#update' do
    let(:cutoff_date) { Rails.configuration.x.simplified_handover_cutoff_date }

    describe 'when offender exists' do
      describe 'when current POM is not the allocated POM' do
        let!(:offender) { stub_mpc_offender(offender_no: nomis_offender_id, handover_type: 'enhanced') }

        before do
          allow(current_pom).to receive(:has_allocation?).with(nomis_offender_id).and_return false
          put :update, params: default_params.merge(handover_progress_checklist: { empty: true })
        end

        it 'responds with unauthorized error' do
          expect(response).to redirect_to('/401')
        end
      end

      describe 'when handover started before cutoff (3-task version)' do
        let!(:offender) do
          stub_mpc_offender(offender_no: nomis_offender_id, handover_type: 'enhanced',
                            model: double(handover_date: cutoff_date))
        end

        describe 'when checklist does not exist' do
          before do
            tasks = {
              reviewed_oasys: true,
              contacted_com: true,
              attended_handover_meeting: true,
            }
            put :update, params: default_params.merge(handover_progress_checklist: tasks)
          end

          it 'creates new checklist with correct data' do
            model = HandoverProgressChecklist.find_by!(nomis_offender_id: nomis_offender_id)
            expect(model).to have_attributes(
              reviewed_oasys: true,
              contacted_com: true,
              attended_handover_meeting: true,
            )
          end

          it 'redirects to the correct handovers url' do
            expect(response).to redirect_to('/last')
          end
        end

        describe 'when checklist already exists' do
          before do
            FactoryBot.create :handover_progress_checklist, nomis_offender_id: nomis_offender_id,
                                                            reviewed_oasys: true,
                                                            contacted_com: false,
                                                            attended_handover_meeting: true
            tasks = {
              reviewed_oasys: false,
              contacted_com: true,
              attended_handover_meeting: false,
            }
            put :update, params: default_params.merge(handover_progress_checklist: tasks)
          end

          it 'updates checklist with correct data' do
            model = HandoverProgressChecklist.find_by!(nomis_offender_id: nomis_offender_id)
            expect(model).to have_attributes(
              reviewed_oasys: false,
              contacted_com: true,
              attended_handover_meeting: false,
            )
          end

          it 'redirects to the correct handovers url' do
            expect(response).to redirect_to('/last')
          end
        end
      end

      describe 'when handover type is standard' do
        let!(:offender) { stub_mpc_offender(offender_no: nomis_offender_id, handover_type: 'standard') }

        it 'filters out enhanced-only task params' do
          tasks = {
            contacted_com: true,
            sent_handover_report: true,
          }

          put :update, params: default_params.merge(handover_progress_checklist: tasks)

          model = HandoverProgressChecklist.find_by!(nomis_offender_id: nomis_offender_id)
          aggregate_failures do
            expect(model.contacted_com).to eq true
            expect(model.sent_handover_report).to eq true
            expect(model.attended_handover_meeting).to eq false
            expect(model.reviewed_oasys).to eq false
          end
        end
      end

      describe 'when handover started after cutoff (2-task version)' do
        let!(:offender) do
          stub_mpc_offender(offender_no: nomis_offender_id, handover_type: 'enhanced',
                            model: double(handover_date: cutoff_date + 1.day))
        end

        it 'persists only the simplified task fields' do
          tasks = {
            reviewed_oasys: true,
            contacted_com: true,
          }

          put :update, params: default_params.merge(handover_progress_checklist: tasks)

          model = HandoverProgressChecklist.find_by!(nomis_offender_id: nomis_offender_id)
          aggregate_failures do
            expect(model.reviewed_oasys).to eq true
            expect(model.contacted_com).to eq true
            expect(model.attended_handover_meeting).to eq false
            expect(model.sent_handover_report).to eq false
          end
        end
      end
    end

    describe 'when offender does not exist' do
      it 'shows error' do
        tasks = { reviewed_oasys: false, contacted_com: false, attended_handover_meeting: false }
        put :update, params: default_params.merge(handover_progress_checklist: tasks)
        expect(response).to redirect_to('/404')
      end
    end
  end
end
