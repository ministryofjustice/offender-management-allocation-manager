require 'rails_helper'

RSpec.describe HandoversController, type: :controller do
  let(:prison) { create(:prison) }
  let(:prison_code) { prison.code }
  let(:default_params) { { new_handover: NEW_HANDOVER_TOKEN, prison_id: prison_code } }
  let(:staff_id) { 456_987 }
  let(:pom_staff_member) { instance_double StaffMember, :pom_staff_member }
  let(:upcoming_handover_allocated_offenders) do
    double(:upcoming_handover_allocated_offenders)
  end
  let(:handover_case_listing) do
    listing = instance_double HandoverCaseListingService, :handover_case_listing,
                              counts: double(:counts),
                              in_progress: double(:in_progress),
                              overdue_tasks: double(:overdue_tasks),
                              com_allocation_overdue: double(:com_allocation_overdue)
    listing
  end

  before do
    allow(controller).to receive(:authenticate_user)
    allow(controller).to receive(:check_prison_access)
    allow(controller).to receive(:load_staff_member)
    allow(controller).to receive(:service_notifications)
    allow(controller).to receive(:load_roles)
    allow(controller).to receive(:ensure_pom)

    controller.instance_variable_set(:@current_user, pom_staff_member)

    allow(handover_case_listing).to receive(:upcoming_handover_allocated_offenders)
                                      .with(pom_staff_member)
                                      .and_return(upcoming_handover_allocated_offenders)
    allow(HandoverCaseListingService).to receive(:new).and_return(handover_case_listing)
  end

  describe 'upcoming handovers page' do
    before do
      get :upcoming, params: default_params
    end

    it 'renders successfully' do
      expect(response).to be_successful
    end

    it 'has counts' do
      expect(assigns(:counts)).to eq handover_case_listing.counts
    end

    it 'has list of upcoming handover cases' do
      expect(assigns(:upcoming_handover_allocated_offenders)).to eq upcoming_handover_allocated_offenders
    end
  end
end
