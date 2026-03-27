# frozen_string_literal: true

require 'rails_helper'

RSpec.describe ReallocationsController, type: :controller do
  render_views

  let(:prison) { create(:prison) }
  let(:old_pom) { build(:pom, :prison_officer, staffId: 10_001, firstName: 'Old', lastName: 'Pom') }
  let(:new_pom) { build(:pom, :probation_officer, staffId: 10_002, firstName: 'New', lastName: 'Pom') }
  let(:poms) { [old_pom, new_pom] }
  let(:offender) do
    build(
      :nomis_offender,
      :inside_omic_policy,
      prisonId: prison.code,
      prisonerNumber: 'G1234AA',
      firstName: 'Alice',
      lastName: 'Zephyr',
      sentence: attributes_for(:sentence_detail,
                               conditionalReleaseDate: '2028-04-01',
                               releaseDate: '2029-04-01')
    )
  end
  let(:offender_no) { offender.fetch(:prisonerNumber) }

  before do
    stub_poms(prison.code, poms)
    stub_signed_in_spo_pom(prison.code, 99_999, 'spo-user')
    stub_offenders_for_prison(prison.code, [offender])

    create(:pom_detail, :inactive, prison_code: prison.code, nomis_staff_id: old_pom.staffId)
    create(:pom_detail, :active, prison_code: prison.code, nomis_staff_id: new_pom.staffId)
    create(:case_information, offender: build(:offender, nomis_offender_id: offender_no), tier: 'A')
    create(:allocation_history,
           prison: prison.code,
           nomis_offender_id: offender_no,
           primary_pom_nomis_id: old_pom.staffId,
           primary_pom_name: old_pom.full_name)
  end

  describe '#index' do
    subject(:perform_request) do
      get :index, params: { prison_id: prison.code, nomis_staff_id: old_pom.staffId }
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
      get :compare_poms,
          params: {
            prison_id: prison.code,
            nomis_staff_id: old_pom.staffId,
            pom_ids: [new_pom.staffId]
          }
    end

    it 'renders the shared comparison rows and reallocation-specific action' do
      perform_request

      expect(response).to be_successful
      expect(response.body).to include('Case mix by role')
      expect(response.body).to include('Case mix by tier')
      expect(response.body).to include('Current workload')
      expect(response.body).to include('Select this POM')
      expect(response.body).not_to include('current-pom')
    end
  end

  describe '#caseload' do
    subject(:perform_request) do
      get :caseload, params: { prison_id: prison.code, nomis_staff_id: old_pom.staffId, new_pom: new_pom.staffId }
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
  end

  describe '#selected_cases' do
    let(:params) do
      {
        prison_id: prison.code,
        nomis_staff_id: old_pom.staffId,
        new_pom: new_pom.staffId,
        nomis_offender_ids: nomis_offender_ids
      }
    end

    context 'when no cases are selected' do
      let(:nomis_offender_ids) { [] }

      it 'returns an unprocessable entity response' do
        post :selected_cases, params: params

        expect(response).to have_http_status(:unprocessable_entity)
        expect(flash[:alert]).to be_nil
      end
    end

    context 'when cases are selected' do
      let(:nomis_offender_ids) { [offender_no] }

      it 'redirects back with a placeholder notice' do
        post :selected_cases, params: params
        expect(response).to redirect_to(caseload_prison_reallocation_path(prison, old_pom.staffId, new_pom.staffId))
      end
    end
  end
end
