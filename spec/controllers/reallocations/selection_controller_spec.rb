# frozen_string_literal: true

require 'rails_helper'

RSpec.describe Reallocations::SelectionController, type: :controller do
  render_views

  include_context 'with reallocation controller defaults'

  let(:route_params) do
    {
      prison_id: prison.code,
      nomis_staff_id: old_pom.staffId
    }
  end

  let(:target_pom_route_params) do
    route_params.merge(new_pom: new_pom.staffId)
  end

  describe '#index' do
    subject(:perform_request) do
      get :index, params: route_params
    end

    let(:response_body) { response.body }
    let(:page) { Nokogiri::HTML(response_body) }
    let(:sortable_headers) { page.css('#available-poms thead th[aria-sort]') }

    it 'renders the POM table with client-side sorting' do
      perform_request

      expect(response).to be_successful
      expect(response_body).to include('data-module="moj-sortable-table"')
      expect(page.css('#available-poms thead th a')).to be_empty
      expect(sortable_headers.map { |header| header['aria-sort'] }).to eq(
        %w[ascending none none none none none none none]
      )
      expect(response_body).to include(new_pom.full_name_ordered)
      expect(page.at_css("a[href='#{caseload_prison_reallocation_path(prison.code, old_pom.staffId, new_pom.staffId)}']").text)
        .to eq(new_pom.full_name_ordered)
      expect(response_body).to include('Select POMs')
      expect(response_body).to include('Compare workloads')
      expect(response_body).to include('Unavailable POMs')
    end

    context 'when the source POM is not inactive or in limbo' do
      before do
        PomDetail.find_by!(prison_code: prison.code, nomis_staff_id: old_pom.staffId).update!(status: 'active')
      end

      it 'redirects to the error page' do
        perform_request

        expect(response).to redirect_to(error_prison_reallocation_path(prison.code, old_pom.staffId))
      end
    end
  end

  describe '#compare_poms' do
    subject(:perform_request) do
      get :compare_poms, params: route_params.merge(pom_ids:)
    end

    let(:pom_ids) { [new_pom.staffId] }

    it 'renders the shared comparison rows and reallocation-specific action' do
      perform_request

      expect(response).to be_successful
      expect(response.body).to include('Case mix by role')
      expect(response.body).to include('Case mix by tier')
      expect(response.body).to include('Current workload')
      expect(response.body).to include('Select this POM')
      expect(response.body).not_to include('current-pom')
    end

    context 'when the submitted compare list includes an unavailable POM' do
      let(:extra_pom) { build(:pom, :prison_officer, staffId: 10_003, firstName: 'Extra', lastName: 'Pom') }

      before do
        stub_poms(prison.code, [old_pom, new_pom, extra_pom])
        create(:pom_detail, :inactive, prison_code: prison.code, nomis_staff_id: extra_pom.staffId)
      end

      it 'redirects back with an alert' do
        get :compare_poms, params: route_params.merge(pom_ids: [extra_pom.staffId])

        expect(response).to redirect_to(prison_reallocation_path(prison.code, old_pom.staffId))
        expect(flash[:alert]).to eq('Choose POMs from the available list to compare workloads')
      end
    end
  end

  describe '#check_compare_list' do
    let(:pom_ids) { [new_pom.staffId] }

    it 'accepts valid compare selections without requiring prisoner_id' do
      put :check_compare_list, params: route_params.merge(pom_ids:)

      expect(response).to redirect_to(compare_poms_prison_reallocation_path(prison.code, old_pom.staffId, pom_ids:))
      expect(flash[:alert]).to be_nil
    end
  end

  describe '#caseload' do
    subject(:perform_request) do
      get :caseload, params: target_pom_route_params
    end

    let(:response_body) { response.body }
    let(:page) { Nokogiri::HTML(response_body) }
    let(:select_case_cell) { page.at_css('td[aria-label="Select case"]') }
    let(:case_cell) { page.at_css('td[aria-label="Case"]') }
    let(:earliest_release_date_cell) { page.at_css('td[aria-label="Earliest release date"]') }
    let(:select_all_label) { page.at_css('label[for="nomis-offender-ids-all"]') }
    let(:select_all_wrapper) { page.at_css('.reallocation-cases-table__select-all') }
    let(:continue_button) { page.at_css('[data-reallocation-continue-button="true"]') }

    it 'renders the dedicated case selection table' do
      perform_request

      expect(response).to be_successful
      expect(assigns(:allocations).map(&:nomis_offender_id)).to eq([offender_no])
      expect(response_body).to include('name="nomis_offender_ids[]"')
      expect(response_body).to include('data-reallocation-select-all="true"')
      expect(response_body).to include('Select all cases (1)')
      expect(response_body).to include('data-module="moj-sortable-table"')
      expect(response_body).to include('aria-sort="ascending">')
      expect(select_all_label).not_to be_nil
      expect(select_all_wrapper).not_to be_nil
      expect(continue_button).not_to be_nil
      expect(select_case_cell['class']).to include('reallocation-cases-table__select-cell')
      expect(case_cell['data-sort-value']).to eq('Zephyr, Alice')
      expect(earliest_release_date_cell['data-sort-value']).to eq('2028-04-01')
      expect(response_body).to include('Recommended POM')
      expect(response_body).to include('Additional')
    end

    context 'when the destination POM is not active' do
      before do
        PomDetail.find_by!(prison_code: prison.code, nomis_staff_id: new_pom.staffId).update!(status: 'inactive')
      end

      it 'redirects to the error page' do
        perform_request

        expect(response).to redirect_to(error_prison_reallocation_path(prison.code, old_pom.staffId))
      end
    end

    context "when reallocating cases in the women's estate" do
      let(:prison) { create(:womens_prison) }

      it 'shows the complexity column' do
        perform_request

        expect(response).to be_successful
        expect(response.body).to include('Complexity level')
      end
    end
  end

  describe '#create' do
    let(:params) do
      target_pom_route_params.merge(nomis_offender_ids: nomis_offender_ids)
    end

    context 'when no cases are selected' do
      let(:nomis_offender_ids) { [] }

      it 'redirects back to the caseload with an alert' do
        post :create, params: params

        expect(response).to redirect_to(caseload_prison_reallocation_path(prison, old_pom.staffId, new_pom.staffId))
        expect(flash[:alert]).to eq('Choose at least one case to reallocate.')
      end
    end

    context 'when cases are selected' do
      let(:nomis_offender_ids) { [offender_no] }

      it 'redirects to the confirmation step when no overrides are needed' do
        post :create, params: params

        expect(response).to redirect_to(summary_prison_reallocation_path(prison, old_pom.staffId, new_pom.staffId))
      end
    end

    context 'when a selected case needs an override' do
      let(:offenders_in_prison) { [offender, override_offender] }
      let(:nomis_offender_ids) { [override_offender_no] }

      before do
        create_reallocation_case(override_offender_no, tier: 'C')
      end

      it 'redirects to the first override step' do
        post :create, params: params

        expect(response).to redirect_to(override_prison_reallocation_path(prison, old_pom.staffId, new_pom.staffId, override_offender_no))
      end
    end
  end
end
