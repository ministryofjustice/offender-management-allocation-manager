require 'rails_helper'

RSpec.describe PomsController, type: :controller do
  let(:prison) { build(:prison) }

  before do
    stub_sso_data(prison.code)
    inactive = create(:pom_detail, :inactive)
    active = create(:pom_detail, :active)
    unavailable = create(:pom_detail, :unavailable)
    stub_poms(prison.code, [
      build(:pom, staffId: inactive.nomis_staff_id),
      build(:pom, staffId: active.nomis_staff_id),
      build(:pom, staffId: unavailable.nomis_staff_id)
    ])
    create(:allocation, primary_pom_nomis_id: active.nomis_staff_id, prison: prison.code)
    create(:allocation, primary_pom_nomis_id: inactive.nomis_staff_id, secondary_pom_nomis_id: active.nomis_staff_id, prison: prison.code)
  end

  render_views

  it 'shows the correct counts on index' do
    get :index, params: { prison_id: prison.code }

    expect(response).to be_successful

    expect(assigns(:inactive_poms).count).to eq(1)
    expect(assigns(:active_poms).count).to eq(2)

    active_pom = assigns(:active_poms).detect { |pom| pom.status == 'active' }
    # one primary, one co-working
    expect(active_pom.total_cases).to eq(2)
  end
end
