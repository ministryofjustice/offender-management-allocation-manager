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
    let(:select_all_labels) { page.css('.reallocation-cases-table__select-all label') }
    let(:select_all_wrapper) { page.at_css('.reallocation-cases-table__select-all') }
    let(:continue_button) { page.at_css('input[type="submit"][value="Continue"]') }

    it 'renders the dedicated case selection table' do
      perform_request

      expect(response).to be_successful
      expect(assigns(:allocations).map(&:nomis_offender_id)).to eq([offender_no])
      expect(response_body).to include('name="nomis_offender_ids[]"')
      expect(response_body).to include('data-module="moj-sortable-table"')
      expect(page.at_css('#reallocation-cases th[aria-sort="ascending"]').text.strip).to eq('Earliest release date')
      expect(select_all_wrapper).not_to be_nil
      expect(continue_button).not_to be_nil
      expect(select_case_cell['class']).to include('reallocation-cases-table__select-cell')
      expect(case_cell['data-sort-value']).to eq('Zephyr, Alice')
      expect(earliest_release_date_cell['data-sort-value']).to eq('2028-04-01')
      expect(response_body).to include('Recommended POM')
      expect(response_body).to include('Additional')
    end

    it 'renders select-all checkboxes at both top and bottom of the table' do
      perform_request

      select_all_checkboxes = page.css('[data-reallocation-select-all="true"]')
      expect(select_all_checkboxes.size).to eq(2)
      expect(page.at_css('#nomis-offender-ids-all-top')).not_to be_nil
      expect(page.at_css('#nomis-offender-ids-all-bottom')).not_to be_nil
      expect(select_all_labels.size).to eq(2)
      expect(select_all_labels.map(&:text).uniq.first).to include('Select all cases (1)')
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

    describe 'Recommended POM type cell' do
      def recommended_cell_for(noms_id)
        page.at_css("#case-#{noms_id}")&.ancestors('tr')&.first&.at_css('td[aria-label="Recommended POM type"]')
      end

      context 'when a recommendation is available' do
        it 'shows the recommendation as plain text without a highlight' do
          perform_request

          cell = recommended_cell_for(offender_no)
          expect(cell.text.strip).to eq('Probation POM')
          expect(cell.at_css('.highlight-primary')).to be_nil
          expect(cell.at_css('.highlight-secondary')).to be_nil
        end
      end

      context 'when there is no recommendation (missing ROSH)' do
        let(:no_rec_offender_no) { 'G7777NR' }
        let(:no_rec_offender) do
          build(
            :nomis_offender,
            :inside_omic_policy,
            prisonId: prison.code,
            prisonerNumber: no_rec_offender_no,
            firstName: 'Dana',
            lastName: 'NoRosh',
            sentence: attributes_for(:sentence_detail, conditionalReleaseDate: '2028-07-01', releaseDate: '2029-07-01')
          )
        end
        let(:offenders_in_prison) { [no_rec_offender] }

        before do
          AllocationHistory.find_by(nomis_offender_id: offender_no)&.destroy
          CaseInformation.joins(:offender).where(offender: { nomis_offender_id: offender_no }).destroy_all
          create_reallocation_case(no_rec_offender_no, tier: 'B', rosh_level: nil)
          stub_oasys_assessments(no_rec_offender_no)
        end

        it 'shows alert-highlighted "No POM type recommendation" with "Missing ROSH"' do
          perform_request

          cell = recommended_cell_for(no_rec_offender_no)
          primary = cell.at_css('.highlight-primary.highlight-alert')
          secondary = cell.at_css('.highlight-secondary.highlight-alert')

          expect(primary.text.strip).to eq('No POM type recommendation')
          expect(secondary.text.strip).to eq('Missing ROSH')
        end
      end
    end

    context 'when the target POM is already the co-working POM on a case' do
      let(:coworker_offender_no) { 'G9999CC' }
      let(:coworker_offender) do
        build(
          :nomis_offender,
          :inside_omic_policy,
          prisonId: prison.code,
          prisonerNumber: coworker_offender_no,
          firstName: 'Charlie',
          lastName: 'Brown',
          sentence: attributes_for(:sentence_detail, conditionalReleaseDate: '2028-06-01', releaseDate: '2029-06-01')
        )
      end
      let(:offenders_in_prison) { [offender, coworker_offender] }

      before do
        create(:case_information, tier: 'B', offender: build(:offender, nomis_offender_id: coworker_offender_no))
        create(
          :allocation_history,
          prison: prison.code,
          nomis_offender_id: coworker_offender_no,
          primary_pom_nomis_id: old_pom.staffId,
          primary_pom_name: old_pom.full_name,
          secondary_pom_nomis_id: new_pom.staffId,
          secondary_pom_name: new_pom.full_name
        )
        stub_oasys_assessments(coworker_offender_no)
      end

      it 'renders a disabled checkbox for the conflicting case' do
        perform_request

        page = Nokogiri::HTML(response.body)
        conflicting_checkbox = page.at_css("#case-#{coworker_offender_no}")
        normal_checkbox = page.at_css("#case-#{offender_no}")

        expect(conflicting_checkbox).not_to be_nil
        expect(conflicting_checkbox['disabled']).to eq('disabled')
        expect(normal_checkbox).not_to be_nil
        expect(normal_checkbox['disabled']).to be_nil
      end

      it 'shows neutral-highlighted recommendation with "already allocated as co-working POM"' do
        perform_request

        page = Nokogiri::HTML(response.body)
        coworker_row = page.at_css("#case-#{coworker_offender_no}")&.ancestors('tr')&.first
        cell = coworker_row.at_css('td[aria-label="Recommended POM type"]')
        primary = cell.at_css('.highlight-primary.highlight-neutral')
        secondary = cell.at_css('.highlight-secondary.highlight-neutral')

        expect(primary.text.strip).to eq('Probation POM')
        expect(secondary.text).to include('already allocated as co-working POM')
      end

      it 'adjusts the select-all count to exclude the conflicting case' do
        perform_request

        expect(response.body).to include('Select all cases (1)')
      end

      context 'when the co-working case also has no recommendation (missing ROSH)' do
        before do
          CaseInformation.joins(:offender)
                         .where(offender: { nomis_offender_id: coworker_offender_no })
                         .update_all(rosh_level: nil)
        end

        it 'shows neutral highlight (co-worker conflict takes priority over alert)' do
          perform_request

          page = Nokogiri::HTML(response.body)
          coworker_row = page.at_css("#case-#{coworker_offender_no}")&.ancestors('tr')&.first
          cell = coworker_row.at_css('td[aria-label="Recommended POM type"]')
          primary = cell.at_css('.highlight-primary.highlight-neutral')
          secondary = cell.at_css('.highlight-secondary.highlight-neutral')

          expect(primary.text.strip).to eq('No POM type recommendation')
          expect(secondary.text).to include('already allocated as co-working POM')
        end
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
        expect(flash[:alert]).to eq('Select at least one case to reallocate')
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
        create_reallocation_case(override_offender_no, tier: 'C', rosh_level: 'LOW')
      end

      it 'redirects to the first override step' do
        post :create, params: params

        expect(response).to redirect_to(override_prison_reallocation_path(prison, old_pom.staffId, new_pom.staffId, override_offender_no))
      end
    end

    context 'when a selected case has the target POM as co-worker (form manipulation)' do
      let(:coworker_offender_no) { 'G9999CC' }
      let(:coworker_offender) do
        build(
          :nomis_offender,
          :inside_omic_policy,
          prisonId: prison.code,
          prisonerNumber: coworker_offender_no,
          firstName: 'Charlie',
          lastName: 'Brown',
          sentence: attributes_for(:sentence_detail, conditionalReleaseDate: '2028-06-01', releaseDate: '2029-06-01')
        )
      end
      let(:offenders_in_prison) { [offender, coworker_offender] }
      let(:nomis_offender_ids) { [coworker_offender_no] }

      before do
        create(:case_information, tier: 'B', offender: build(:offender, nomis_offender_id: coworker_offender_no))
        create(
          :allocation_history,
          prison: prison.code,
          nomis_offender_id: coworker_offender_no,
          primary_pom_nomis_id: old_pom.staffId,
          primary_pom_name: old_pom.full_name,
          secondary_pom_nomis_id: new_pom.staffId,
          secondary_pom_name: new_pom.full_name
        )
        stub_oasys_assessments(coworker_offender_no)
      end

      it 'rejects the conflicting case and redirects with an alert' do
        post :create, params: params

        expect(response).to redirect_to(caseload_prison_reallocation_path(prison, old_pom.staffId, new_pom.staffId))
        expect(flash[:alert]).to eq('Select at least one case to reallocate')
      end
    end
  end
end
