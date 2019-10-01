require 'rails_helper'

RSpec.describe OverridesController, type: :controller do
  before do
    stub_sso_data(prison)
  end

  let(:prison) { 'WEI' }
  let(:nomis_staff_id) { 'A12345' }
  let(:nomis_offender_id) { 'B44455' }

  let(:params) do
    { prison_id: prison }
  end

  let(:override_params) do
    {
      override: { nomis_offender_id: nomis_offender_id,
                  nomis_staff_id: nomis_staff_id,
                  more_detail: nil,
                  suitability_detail: "Too high risk",
                  override_reasons: ["continuity"]
      }
    }
  end

  context 'when creating an override' do
    it 'redirects to confirm#allocation when offender has no previous allocations' do
      post :create, params: params.merge(override_params)

      expect(response).to redirect_to prison_confirm_allocation_path(prison, nomis_offender_id, nomis_staff_id)
    end

    it 'redirects to confirm#reallocation when offender has been previously allocated' do
      allow(AllocationService).to receive(:previously_allocated_poms).and_return([nomis_offender_id])

      post :create, params: params.merge(override_params)

      expect(response).to redirect_to prison_confirm_reallocation_path(prison, nomis_offender_id, nomis_staff_id)
    end
  end
end
