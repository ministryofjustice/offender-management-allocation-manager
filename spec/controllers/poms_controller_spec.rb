# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PomsController, type: :controller do
  let(:prison) { create(:prison) }
  let(:a_offenders) { build_list(:nomis_offender, 2) }
  let(:b_offenders) { build_list(:nomis_offender, 4) }
  let(:c_offenders) { build_list(:nomis_offender, 3) }
  let(:d_offenders) { build_list(:nomis_offender, 1) }
  let(:na_offenders) { build_list(:nomis_offender, 5) }

  before do
    stub_sso_data(prison.code)
    inactive = create(:pom_detail, :inactive, prison_code: prison.code)
    active = create(:pom_detail, :active, prison_code: prison.code)
    unavailable = create(:pom_detail, :unavailable, prison_code: prison.code)
    stub_poms(prison.code, [
      build(:pom, staffId: inactive.nomis_staff_id),
      build(:pom, staffId: active.nomis_staff_id),
      build(:pom, staffId: unavailable.nomis_staff_id)
    ])
    a1 = create(:case_information, tier: 'A', offender: build(:offender, nomis_offender_id: a_offenders.first.fetch(:prisonerNumber)))
    create(:allocation_history, nomis_offender_id: a1.nomis_offender_id, primary_pom_nomis_id: active.nomis_staff_id, prison: prison.code)

    a2 = create(:case_information, tier: 'A', offender: build(:offender, nomis_offender_id: a_offenders.last.fetch(:prisonerNumber)))
    create(:allocation_history, nomis_offender_id: a2.nomis_offender_id, primary_pom_nomis_id: inactive.nomis_staff_id, secondary_pom_nomis_id: active.nomis_staff_id, prison: prison.code)

    {
      'B': b_offenders,
      'C': c_offenders,
      'D': d_offenders,
      'N/A': na_offenders
    }.each do |tier, offenders|
      offenders.map { |o| o.fetch(:prisonerNumber) }.each do |offender_no|
        create(:case_information, tier: tier.to_s, offender: build(:offender, nomis_offender_id: offender_no))
        create(:allocation_history, nomis_offender_id: offender_no, primary_pom_nomis_id: active.nomis_staff_id, prison: prison.code)
      end
    end
  end

  render_views

  context 'with an extra unsentenced offender' do
    before do
      # This guy doesn't turn up in Prison#offenders, and hence doesn't show up on caseload or stats
      missing_offender = create(:case_information)
      create(:allocation_history, nomis_offender_id: missing_offender.nomis_offender_id, primary_pom_nomis_id: active_staff_id, prison: prison.code)

      stub_request(:get, "#{ApiHelper::NOMIS_USER_ROLES_API_HOST}/users/staff/#{active_staff_id}")
        .to_return(body: { staffId: active_staff_id, lastName: 'LastName', firstName: 'FirstName' }.to_json)

      offenders = a_offenders + b_offenders + c_offenders + d_offenders + na_offenders

      stub_offenders_for_prison(prison.code, offenders)
    end

    let(:active_staff_id) { PomDetail.where(status: 'active').first!.nomis_staff_id }
    let(:unavailable_staff_id) { PomDetail.where(status: 'unavailable').first!.nomis_staff_id }
    let(:inactive_poms) { assigns(:poms).reject { |pom| %w[active unavailable].include? pom.status } }
    let(:active_poms) { assigns(:poms).select { |pom| %w[active unavailable].include? pom.status } }

    it 'does omit the allocation which does not show up in Prison#offenders' do
      get :index, params: { prison_id: prison.code }
      expect(response).to be_successful

      expect(inactive_poms.count).to eq(1)
      active_poms_list = active_poms.map do |pom|
        {
          staff_id: pom.staff_id,
          tier_a: pom.allocations.count { |a| a.tier == 'A' },
          tier_b: pom.allocations.count { |a| a.tier == 'B' },
          tier_c: pom.allocations.count { |a| a.tier == 'C' },
          tier_d: pom.allocations.count { |a| a.tier == 'D' },
          no_tier: pom.allocations.count { |a| a.tier == 'N/A' },
          total_cases: pom.allocations.count
        }
      end

      expect(active_poms_list).to match_array [{ staff_id: active_staff_id,
                                                 tier_a: 2,
                                                 tier_b: 4,
                                                 tier_c: 3,
                                                 tier_d: 1,
                                                 no_tier: 5,
                                                 total_cases: 15 },
                                               { staff_id: unavailable_staff_id,
                                                 tier_a: 0,
                                                 tier_b: 0,
                                                 tier_c: 0,
                                                 tier_d: 0,
                                                 no_tier: 0,
                                                 total_cases: 0 }]
    end

    it 'shows the caseload on the show action' do
      get :show, params: { prison_id: prison.code, nomis_staff_id: active_staff_id }
      expect(response).to be_successful
      expect(assigns(:allocations).map(&:tier)).to match_array(["A",
                                                                'A',
                                                                "B",
                                                                "B",
                                                                "B",
                                                                "B",
                                                                "C",
                                                                "C",
                                                                "C",
                                                                "D",
                                                                "N/A",
                                                                "N/A",
                                                                "N/A",
                                                                "N/A",
                                                                "N/A"])
    end
  end

  describe 'GET #confirm_removal' do
    let(:removed_staff_id) { 123_987 }

    before do
      create(:pom_detail, :inactive, prison_code: prison.code, nomis_staff_id: removed_staff_id)
      stub_request(:get, "#{ApiHelper::NOMIS_USER_ROLES_API_HOST}/users/staff/#{removed_staff_id}")
        .to_return(body: { staffId: removed_staff_id, lastName: 'Example', firstName: 'Mateo' }.to_json)
    end

    it 'renders an intermediate confirmation page before deletion' do
      get :confirm_removal, params: { prison_id: prison.code, nomis_staff_id: removed_staff_id, from: 'attention_needed' }

      expect(response).to be_successful
      expect(response.body).to include('Confirm Mateo Example can be removed from this service')
      expect(response.body).to include('Choose continue to confirm they can be removed from this service once their cases have been reallocated.')
      expect(response.body).to include(prison_pom_path(prison.code, removed_staff_id))
    end
  end

  describe 'GET #index' do
    let(:removed_staff_id) { 123_888 }
    let(:removed_offender) { build(:nomis_offender) }
    let(:limbo_bulk_reallocation_enabled) { true }

    before do
      allow(FeatureFlags.instance).to receive(:config).and_return(
        {
          limbo_bulk_reallocation: {
            test: limbo_bulk_reallocation_enabled,
          }
        }.with_indifferent_access
      )

      create(:pom_detail, :inactive, prison_code: prison.code, nomis_staff_id: removed_staff_id)
      create(:case_information, offender: build(:offender, nomis_offender_id: removed_offender.fetch(:prisonerNumber)))
      create(:allocation_history,
             nomis_offender_id: removed_offender.fetch(:prisonerNumber),
             primary_pom_nomis_id: removed_staff_id,
             prison: prison.code)

      stub_request(:get, "#{ApiHelper::NOMIS_USER_ROLES_API_HOST}/users/staff/#{removed_staff_id}")
        .to_return(body: { staffId: removed_staff_id, lastName: 'Example', firstName: 'Mateo' }.to_json)
      stub_offenders_for_prison(prison.code, [removed_offender])
    end

    context 'when limbo bulk reallocation is enabled' do
      let(:limbo_bulk_reallocation_enabled) { true }

      it 'links removed poms to the confirmation page' do
        get :index, params: { prison_id: prison.code }

        expect(response).to be_successful
        expect(response.body).to include('Reallocate cases')
        expect(response.body).to include(confirm_removal_prison_pom_path(prison.code, removed_staff_id, from: 'attention_needed'))
      end
    end

    context 'when limbo bulk reallocation is disabled' do
      let(:limbo_bulk_reallocation_enabled) { false }

      it 'renders the legacy remove action' do
        get :index, params: { prison_id: prison.code }

        expect(response).to be_successful
        expect(response.body).to include('Remove POM')
        expect(response.body).to include(prison_pom_path(prison.code, removed_staff_id))
        expect(response.body).not_to include(confirm_removal_prison_pom_path(prison.code, removed_staff_id, from: 'attention_needed'))
      end
    end
  end

  describe 'DELETE #destroy' do
    let(:removed_staff_id) { 123_654 }

    before do
      create(:pom_detail, :inactive, prison_code: prison.code, nomis_staff_id: removed_staff_id)
      stub_request(:get, "#{ApiHelper::NOMIS_USER_ROLES_API_HOST}/users/staff/#{removed_staff_id}")
        .to_return(body: { staffId: removed_staff_id, lastName: 'Example', firstName: 'Mateo' }.to_json)
      allow(NomisUserRolesService).to receive(:remove_pom).with(prison, removed_staff_id).and_return(true)
    end

    it 'removes the pom and redirects back to the attention needed tab' do
      delete :destroy, params: { prison_id: prison.code, nomis_staff_id: removed_staff_id, from: 'attention_needed' }

      expect(NomisUserRolesService).to have_received(:remove_pom).with(prison, removed_staff_id)
      expect(response).to redirect_to(prison_poms_path(anchor: 'attention_needed!top'))
      expect(flash[:notice]).to eq('Mateo Example removed. If necessary, their cases have been moved to @unallocated_link@.')
    end
  end
end
