require 'rails_helper'

RSpec.describe PomsController, :allocation, type: :controller do
  let(:prison) { build(:prison) }
  let(:a_offenders) { build_list(:nomis_offender, 2) }
  let(:b_offenders) { build_list(:nomis_offender, 4) }
  let(:c_offenders) { build_list(:nomis_offender, 3) }
  let(:d_offenders) { build_list(:nomis_offender, 1) }
  let(:na_offenders) { build_list(:nomis_offender, 5) }

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
    a1 = create(:case_information, tier: 'A', nomis_offender_id: a_offenders.first.fetch(:offenderNo))
    create(:allocation, nomis_offender_id: a1.nomis_offender_id, primary_pom_nomis_id: active.nomis_staff_id, prison: prison.code)

    a2 = create(:case_information, tier: 'A', nomis_offender_id: a_offenders.last.fetch(:offenderNo))
    create(:allocation, nomis_offender_id: a2.nomis_offender_id, primary_pom_nomis_id: inactive.nomis_staff_id, secondary_pom_nomis_id: active.nomis_staff_id, prison: prison.code)

    {
      'B': b_offenders,
      'C': c_offenders,
      'D': d_offenders,
      'N/A': na_offenders
    }.each do |tier, offenders|
      offenders.map { |o| o.fetch(:offenderNo) }.each do |offender_no|
        create(:case_information, tier: tier.to_s, nomis_offender_id: offender_no)
        create(:allocation, nomis_offender_id: offender_no, primary_pom_nomis_id: active.nomis_staff_id, prison: prison.code)
      end
    end
  end

  render_views

  context 'with an extra unsentenced offender' do
    let(:active_staff_id) { PomDetail.where(status: 'active').first!.nomis_staff_id }
    let(:unavailable_staff_id) { PomDetail.where(status: 'unavailable').first!.nomis_staff_id }

    before do
      # This guy doesn't turn up in Prison#offenders, and hence doesn't show up on caseload or stats
      missing_offender = create(:case_information)
      create(:allocation, nomis_offender_id: missing_offender.nomis_offender_id, primary_pom_nomis_id: active_staff_id, prison: prison.code)

      stub_request(:get, "#{ApiHelper::T3}/staff/#{active_staff_id}").
        to_return(body: { staffId: active_staff_id, lastName: 'LastName', firstName: 'FirstName' }.to_json)

      offenders = a_offenders + b_offenders + c_offenders + d_offenders + na_offenders

      stub_offenders_for_prison(prison.code, offenders)
    end

    it 'does omit the allocation which does not show up in Prison#offenders' do
      get :index, params: { prison_id: prison.code }
      expect(response).to be_successful

      expect(assigns(:inactive_poms).count).to eq(1)
      active_poms = assigns(:active_poms).map do |pom|
        {
          staff_id: pom.staff_id,
          tier_a: pom.tier_a, tier_b: pom.tier_b, tier_c: pom.tier_c, tier_d: pom.tier_d, no_tier: pom.no_tier,
          total_cases: pom.total_cases
        }
      end

      expect(active_poms).to match_array [{ staff_id: active_staff_id,
                                           tier_a: 2, tier_b: 4, tier_c: 3, tier_d: 1, no_tier: 5,
                                           total_cases: 15 },
                                          { staff_id: unavailable_staff_id,
                                            tier_a: 0, tier_b: 0, tier_c: 0, tier_d: 0, no_tier: 0,
                                            total_cases: 0 }]
    end

    it 'shows the caseload on the show action' do
      get :show, params: { prison_id: prison.code, nomis_staff_id: active_staff_id }
      expect(response).to be_successful
      expect(assigns(:allocations).map(&:tier)).to match_array(["A", 'A',
                                                                "B", "B", "B", "B",
                                                                "C", "C", "C",
                                                                "D",
                                                                "N/A", "N/A", "N/A", "N/A", "N/A"])
    end
  end
end
