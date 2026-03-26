# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'reallocations/index', type: :view do
  let(:page) { Capybara.string(rendered) }
  let(:prison) { create(:prison) }
  let(:source_pom_record) do
    build(:pom,
          :prison_officer,
          staffId: 10_001,
          firstName: 'Source',
          lastName: 'Pom')
  end
  let(:available_pom_records) do
    [
      build(:pom, :prison_officer, staffId: 10_002, firstName: 'Alice', lastName: 'Jones'),
      build(:pom, :probation_officer, staffId: 10_003, firstName: 'Brian', lastName: 'Smith')
    ]
  end
  let(:all_pom_records) { [source_pom_record] + available_pom_records }
  let(:source_pom) { StaffMember.new(prison, source_pom_record.staff_id) }
  let(:available_poms) { available_pom_records.map { |pom| StaffMember.new(prison, pom.staff_id) } }

  before do
    stub_poms(prison.code, all_pom_records)
    stub_offenders_for_prison(prison.code, [])

    view.request.path_parameters[:prison_id] = prison.code
    view.request.path_parameters[:nomis_staff_id] = source_pom.staff_id

    allow(source_pom).to receive(:primary_allocations_count).and_return(7)

    assign(:prison, prison)
    assign(:pom, source_pom)
    assign(:available_poms, available_poms)
    assign(:prison_poms, available_poms.select(&:prison_officer?))
    assign(:probation_poms, available_poms.select(&:probation_officer?))
  end

  it 'renders the reallocation-specific wrapper around the shared POM selection table' do
    render

    expect(page).to have_link('Back', href: reallocate_prison_pom_path(prison.code, source_pom.staff_id))
    expect(page).to have_text('Choose a POM to reallocate cases to')
    expect(page).to have_text("Reallocating from: prison POM #{source_pom.full_name_ordered}")
    expect(page).to have_text('Cases remaining: 7')
    expect(page).to have_css('#available-poms[data-module="moj-sortable-table"]')
    expect(page).to have_text('Select POMs')
    expect(page).to have_css('input[value="Compare workloads"]')

    available_poms.each do |available_pom|
      expect(page).to have_link(
        available_pom.full_name_ordered,
        href: caseload_prison_reallocation_path(prison.code, source_pom.staff_id, new_pom: available_pom.staff_id)
      )
    end
  end

  context 'when there is a selection error' do
    before do
      flash[:alert] = 'Choose at least one POM to compare workloads'
    end

    it 'renders the error summary linked to the first checkbox' do
      render

      expect(page).to have_css('#pom-selection-error')
      expect(page).to have_link('Choose at least one POM to compare workloads', href: '#pom-select-10002')
    end

    context 'when there are no available POMs' do
      before do
        assign(:available_poms, [])
        assign(:prison_poms, [])
        assign(:probation_poms, [])
      end

      it 'renders the error summary without raising and falls back to the summary anchor' do
        render

        expect(page).to have_css('#pom-selection-error')
        expect(page).to have_link('Choose at least one POM to compare workloads', href: '#pom-selection-error')
      end
    end
  end
end
