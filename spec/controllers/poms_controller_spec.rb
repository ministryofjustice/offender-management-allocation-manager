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
    a1 = create(:case_information)
    create(:allocation, nomis_offender_id: a1.nomis_offender_id, primary_pom_nomis_id: active.nomis_staff_id, prison: prison.code)

    a2 = create(:case_information)
    create(:allocation, nomis_offender_id: a2.nomis_offender_id, primary_pom_nomis_id: inactive.nomis_staff_id, secondary_pom_nomis_id: active.nomis_staff_id, prison: prison.code)

    b1 = create(:case_information, tier: 'B')
    create(:allocation, nomis_offender_id: b1.nomis_offender_id, primary_pom_nomis_id: active.nomis_staff_id, prison: prison.code)
    b2 = create(:case_information, tier: 'B')
    create(:allocation, nomis_offender_id: b2.nomis_offender_id, primary_pom_nomis_id: active.nomis_staff_id, prison: prison.code)
    b3 = create(:case_information, tier: 'B')
    create(:allocation, nomis_offender_id: b3.nomis_offender_id, primary_pom_nomis_id: active.nomis_staff_id, prison: prison.code)
    b4 = create(:case_information, tier: 'B')
    create(:allocation, nomis_offender_id: b4.nomis_offender_id, primary_pom_nomis_id: active.nomis_staff_id, prison: prison.code)

    c1 = create(:case_information, tier: 'C')
    create(:allocation, nomis_offender_id: c1.nomis_offender_id, primary_pom_nomis_id: active.nomis_staff_id, prison: prison.code)
    c2 = create(:case_information, tier: 'C')
    create(:allocation, nomis_offender_id: c2.nomis_offender_id, primary_pom_nomis_id: active.nomis_staff_id, prison: prison.code)
    c3 = create(:case_information, tier: 'C')
    create(:allocation, nomis_offender_id: c3.nomis_offender_id, primary_pom_nomis_id: active.nomis_staff_id, prison: prison.code)

    d1 = create(:case_information, tier: 'D')
    create(:allocation, nomis_offender_id: d1.nomis_offender_id, primary_pom_nomis_id: active.nomis_staff_id, prison: prison.code)
  end

  render_views

  it 'shows the correct counts on index' do
    get :index, params: { prison_id: prison.code }

    expect(response).to be_successful

    expect(assigns(:inactive_poms).count).to eq(1)
    expect(assigns(:active_poms).count).to eq(2)

    active_pom = assigns(:active_poms).detect { |pom| pom.status == 'active' }

    expect(active_pom.tier_a).to eq(2)
    expect(active_pom.tier_b).to eq(4)
    expect(active_pom.tier_c).to eq(3)
    expect(active_pom.tier_d).to eq(1)

    expect(active_pom.total_cases).to eq(10)
  end
end
