require 'rails_helper'

RSpec.describe HandoversController, type: :controller do
  let(:prison_code) { create(:prison).code }
  let(:default_params) { { new_handover: NEW_HANDOVER_TOKEN, prison_id: prison_code } }

  let(:handover_case_listing) do
    instance_double HandoverCaseListingService, :handover_case_listing,
                    counts: double(:counts),
                    upcoming_handover_allocated_offenders: double(:upcoming_handover_allocated_offenders),
                    in_progress: double(:in_progress),
                    overdue_tasks: double(:overdue_tasks),
                    com_allocation_overdue: double(:com_allocation_overdue)
  end

  before do
    stub_sso_data(prison_code)

    allow(HandoverCaseListingService).to receive(:new).and_return(handover_case_listing)
  end

  describe 'index page' do
    it 'redirects to upcoming handovers' do
      get :index, params: default_params
      expect(response).to redirect_to(upcoming_prison_handovers_path(**default_params))
    end
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
      expect(assigns(:upcoming_handover_allocated_offenders)).to eq handover_case_listing.upcoming_handover_allocated_offenders
    end
  end
end
