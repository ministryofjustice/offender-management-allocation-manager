# frozen_string_literal: true

require 'rails_helper'

RSpec.describe PomsController, type: :controller do
  let(:prison) { create(:prison) }
  let(:a_offenders) { build_list(:nomis_offender, 2) }
  let(:b_offenders) { build_list(:nomis_offender, 4) }
  let(:c_offenders) { build_list(:nomis_offender, 3) }
  let(:d_offenders) { build_list(:nomis_offender, 1) }

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

      offenders = a_offenders + b_offenders + c_offenders + d_offenders

      stub_offenders_for_prison(prison.code, offenders)
    end

    let(:active_staff_id) { PomDetail.where(status: 'active').first!.nomis_staff_id }
    let(:unavailable_staff_id) { PomDetail.where(status: 'unavailable').first!.nomis_staff_id }
    let(:inactive_poms) { assigns(:poms).select(&:inactive?) }
    let(:active_poms) { assigns(:poms).select { |pom| %w[active unavailable].include? pom.status } }

    it 'does omit the allocation which does not show up in Prison#offenders' do
      get :index, params: { prison_id: prison.code }
      expect(response).to be_successful

      expect(inactive_poms.count).to eq(1)
      expect(response.body).not_to include('No POMs away from work.')

      active_poms_list = active_poms.map do |pom|
        {
          staff_id: pom.staff_id,
          tier_a: pom.allocations.count { |a| a.tier == 'A' },
          tier_b: pom.allocations.count { |a| a.tier == 'B' },
          tier_c: pom.allocations.count { |a| a.tier == 'C' },
          tier_d: pom.allocations.count { |a| a.tier == 'D' },
          total_cases: pom.allocations.count
        }
      end

      expect(active_poms_list).to match_array [{ staff_id: active_staff_id,
                                                 tier_a: 2,
                                                 tier_b: 4,
                                                 tier_c: 3,
                                                 tier_d: 1,
                                                 total_cases: 10 },
                                               { staff_id: unavailable_staff_id,
                                                 tier_a: 0,
                                                 tier_b: 0,
                                                 tier_c: 0,
                                                 tier_d: 0,
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
                                                                "D"])
    end
  end

  context 'when there are no inactive POMs' do
    before do
      PomDetail.where(status: 'inactive').destroy_all
      stub_offenders_for_prison(prison.code, a_offenders + b_offenders + c_offenders + d_offenders)
    end

    it 'shows the empty state message in the away from work tab' do
      get :index, params: { prison_id: prison.code }
      expect(response).to be_successful
      expect(response.body).to include('No POMs away from work.')
    end
  end

  describe 'PUT #update' do
    let(:updated_staff_id) { 123_456 }

    before do
      create(:pom_detail, :active, prison_code: prison.code, nomis_staff_id: updated_staff_id)
      stub_poms(prison.code, [build(:pom, staffId: updated_staff_id, firstName: 'Mateo', lastName: 'Example')])
    end

    context 'when the update is valid' do
      it 'redirects to the canonical show URL' do
        put :update, params: {
          prison_id: prison.code,
          nomis_staff_id: updated_staff_id,
          edit_pom: { status: 'active', description: 'PT', working_pattern: '0.8' },
        }

        expect(response).to redirect_to(prison_pom_path(prison.code, nomis_staff_id: updated_staff_id))
        expect(flash[:notice]).to eq('Profile updated for Mateo Example')
      end
    end

    context 'when status is deleted' do
      it 'does not save and redirects to confirm delete page' do
        put :update, params: {
          prison_id: prison.code,
          nomis_staff_id: updated_staff_id,
          edit_pom: { status: 'deleted', description: 'FT', working_pattern: '1.0' },
        }

        expect(response).to redirect_to(confirm_delete_prison_pom_path(prison.code, updated_staff_id))
        expect(PomDetail.find_by(nomis_staff_id: updated_staff_id).status).to eq('active')
      end
    end
  end

  describe 'GET #confirm_delete' do
    let(:staff_id) { 123_456 }

    before do
      create(:pom_detail, :active, prison_code: prison.code, nomis_staff_id: staff_id)
      stub_poms(prison.code, [build(:pom, staffId: staff_id, firstName: 'Mateo', lastName: 'Example')])
    end

    it 'renders the confirmation page' do
      get :confirm_delete, params: { prison_id: prison.code, nomis_staff_id: staff_id }

      expect(response).to be_successful
      expect(response.body).to include('Are you sure you want to remove')
      expect(response.body).to include('Mateo Example')
    end
  end

  describe 'edit/update guard for deleted POMs' do
    let(:deleted_staff_id) { 123_789 }

    before do
      create(:pom_detail, :deleted, prison_code: prison.code, nomis_staff_id: deleted_staff_id)
      stub_request(:get, "#{ApiHelper::NOMIS_USER_ROLES_API_HOST}/users/staff/#{deleted_staff_id}")
        .to_return(body: { staffId: deleted_staff_id, lastName: 'Removed', firstName: 'Person' }.to_json)
    end

    it 'redirects from edit with an alert' do
      get :edit, params: { prison_id: prison.code, nomis_staff_id: deleted_staff_id }

      expect(response).to redirect_to(prison_pom_path(prison.code, nomis_staff_id: deleted_staff_id))
      expect(flash[:alert]).to eq('This POM has been removed and their profile cannot be edited.')
    end

    it 'redirects from update with an alert' do
      put :update, params: {
        prison_id: prison.code,
        nomis_staff_id: deleted_staff_id,
        edit_pom: { status: 'active', description: 'FT', working_pattern: '1.0' },
      }

      expect(response).to redirect_to(prison_pom_path(prison.code, nomis_staff_id: deleted_staff_id))
      expect(flash[:alert]).to eq('This POM has been removed and their profile cannot be edited.')
    end
  end

  describe 'load_pom_staff_member guard for non-onboarded POMs' do
    let(:unknown_staff_id) { 999_999 }

    before do
      # POM exists in NOMIS but has no local PomDetail onboarding record
      stub_poms(prison.code, [build(:pom, staffId: unknown_staff_id, firstName: 'Unknown', lastName: 'Person')])
    end

    it 'redirects show to staff list with an alert' do
      get :show, params: { prison_id: prison.code, nomis_staff_id: unknown_staff_id }

      expect(response).to redirect_to(prison_poms_path(prison.code))
      expect(flash[:alert]).to eq('This POM cannot be found in this service.')
    end

    it 'redirects confirm_delete to staff list with an alert' do
      get :confirm_delete, params: { prison_id: prison.code, nomis_staff_id: unknown_staff_id }

      expect(response).to redirect_to(prison_poms_path(prison.code))
      expect(flash[:alert]).to eq('This POM cannot be found in this service.')
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

    context 'with confirm delete flow' do
      context 'when confirmed yes and POM has no primary allocations' do
        before do
          allow(NomisUserRolesService).to receive(:remove_pom) do |given_prison, staff_id|
            given_prison.pom_details.find_by!(nomis_staff_id: staff_id).deleted!
            true
          end
        end

        it 'removes POM and redirects to staff page' do
          delete :destroy, params: {
            prison_id: prison.code,
            nomis_staff_id: removed_staff_id,
            confirm_delete_pom: { confirmation: 'yes' },
          }

          expect(NomisUserRolesService).to have_received(:remove_pom).with(prison, removed_staff_id)
          expect(PomDetail.find_by!(nomis_staff_id: removed_staff_id).status).to eq('deleted')
          expect(response).to redirect_to(prison_poms_path(prison.code))
        end
      end

      context 'when confirmed yes and POM has primary allocations' do
        let(:allocated_offender) { build(:nomis_offender) }

        before do
          create(:case_information, offender: build(:offender, nomis_offender_id: allocated_offender.fetch(:prisonerNumber)))
          create(:allocation_history,
                 nomis_offender_id: allocated_offender.fetch(:prisonerNumber),
                 primary_pom_nomis_id: removed_staff_id,
                 prison: prison.code)
          stub_offenders_for_prison(prison.code, [allocated_offender])
        end

        it 'marks as deleted and redirects to reallocate page' do
          delete :destroy, params: {
            prison_id: prison.code,
            nomis_staff_id: removed_staff_id,
            confirm_delete_pom: { confirmation: 'yes' },
          }

          expect(PomDetail.find_by(nomis_staff_id: removed_staff_id).status).to eq('deleted')
          expect(NomisUserRolesService).not_to have_received(:remove_pom)
          expect(response).to redirect_to(reallocate_prison_pom_path(prison.code, nomis_staff_id: removed_staff_id))
        end
      end

      context 'when confirmed no' do
        it 'does not change status and redirects to edit page' do
          delete :destroy, params: {
            prison_id: prison.code,
            nomis_staff_id: removed_staff_id,
            confirm_delete_pom: { confirmation: 'no' },
          }

          expect(PomDetail.find_by(nomis_staff_id: removed_staff_id).status).to eq('inactive')
          expect(NomisUserRolesService).not_to have_received(:remove_pom)
          expect(response).to redirect_to(edit_prison_pom_path(prison.code, removed_staff_id))
        end
      end

      context 'when no option selected' do
        it 're-renders the confirmation page with errors' do
          delete :destroy, params: {
            prison_id: prison.code,
            nomis_staff_id: removed_staff_id,
            confirm_delete_pom: { confirmation: '' },
          }

          expect(response).to be_successful
          expect(response.body).to include('Select yes if you want to remove this POM')
        end
      end
    end
  end
end
