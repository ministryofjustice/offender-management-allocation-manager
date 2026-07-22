# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "allocation_staff/index", type: :view do
  let(:next_year) { (Time.zone.today + 1.year).year }
  let(:case_info) { build(:case_information, enhanced_resourcing: false) }
  let(:api_offender) do
    build(:hmpps_api_offender,
          sentence: attributes_for(:sentence_detail, conditionalReleaseDate: Date.new(next_year + 1, 1, 28)),
          prisonerNumber: case_info.nomis_offender_id)
  end
  let(:offender) { build(:mpc_offender, prison: prison, offender: case_info.offender, prison_record: api_offender) }
  let(:prison) { create(:prison) }
  let(:pom) { build(:pom) }
  let(:page) do
    render
    Capybara.string(rendered)
  end
  let(:poms) { [pom] }
  let(:recent_pom_history) { [] }

  before do
    stub_poms(prison.code, poms)
    stub_offenders_for_prison(prison.code, [])

    assign(:prison, prison)
    assign(:previous_poms, poms.map { |p| StaffMember.new(prison, p.staff_id) })
    assign(:prisoner, offender)
    assign(:case_info, case_info)
    assign(:probation_poms, poms.map { |p| StaffMember.new(prison, p.staff_id) })
    assign(:available_poms, poms.map { |p| StaffMember.new(prison, p.staff_id) })
    assign(:prison_poms, [])
    assign(:recent_pom_history, recent_pom_history)
    assign(:recommended_pom_type, offender.recommended_pom_type)
  end

  it 'renders the allocation-specific wrapper around the shared POM selection table' do
    expect(page).to have_text('Choose a POM')
    expect(page).to have_css('#available-poms[data-module="moj-sortable-table"]')
    expect(page).to have_text('Select POMs')
    expect(page).to have_css('input[value="Compare workloads"]')

    poms.each do |available_pom|
      expect(page).to have_link(
        StaffMember.new(prison, available_pom.staff_id).full_name_ordered,
        href: new_prison_prisoner_staff_build_allocation_path(prison.code, offender.offender_no, available_pom.staff_id)
      )
    end
  end

  it 'sorts by POM type column by default when a recommendation exists' do
    headers = page.all('#available-poms thead th[aria-sort]')
    pom_name_header = headers[0]
    pom_type_header = headers[1]

    expect(pom_name_header[:'aria-sort']).to eq('none')
    expect(pom_type_header[:'aria-sort']).to eq('ascending')
  end

  it 'assigns data-sort-value that puts recommended POM type first' do
    pom_type_cells = page.all('#available-poms tbody td[aria-label="POM role"]')
    sort_values = pom_type_cells.map { |cell| cell[:'data-sort-value'] }

    expect(sort_values).to all(match(/\A[01] /))
  end

  context 'when there is no recommendation' do
    before do
      allow(RecommendationService).to receive(:recommended_pom_type).and_return(nil)
      assign(:recommended_pom_type, nil)
    end

    it 'sorts by POM name column by default' do
      headers = page.all('#available-poms thead th[aria-sort]')
      pom_name_header = headers[0]
      pom_type_header = headers[1]

      expect(pom_name_header[:'aria-sort']).to eq('ascending')
      expect(pom_type_header[:'aria-sort']).to eq('none')
    end

    it 'assigns plain grade as data-sort-value without prefix' do
      pom_type_cells = page.all('#available-poms tbody td[aria-label="POM role"]')
      sort_values = pom_type_cells.map { |cell| cell[:'data-sort-value'] }

      sort_values.each do |value|
        expect(value).not_to match(/\A[01] /)
        expect(value).to match(/POM\z/)
      end
    end
  end

  context 'when a prison POM is recommended' do
    before do
      allow(RecommendationService).to receive(:recommended_pom_type).and_return(RecommendationService::PRISON_POM)
      assign(:recommended_pom_type, RecommendationService::PRISON_POM)
    end

    it 'shows the correct guidance' do
      expect(page).to have_text(
        I18n.t(RecommendationService::PRISON_POM, scope: 'recommendation_service.guidance', name: offender.full_name_ordered)
      )
    end
  end

  context 'when a probation POM is recommended' do
    before do
      allow(RecommendationService).to receive(:recommended_pom_type).and_return(RecommendationService::PROBATION_POM)
      assign(:recommended_pom_type, RecommendationService::PROBATION_POM)
    end

    it 'shows the correct guidance' do
      expect(page).to have_text(
        I18n.t(RecommendationService::PROBATION_POM, scope: 'recommendation_service.guidance', name: offender.full_name_ordered)
      )
    end
  end

  context 'with 1 previous pom' do
    let(:recent_pom_history) do
      [{ name: 'FRED', started_at: Time.zone.now, ended_at: Time.zone.now }]
    end

    it 'says they have been assigned' do
      expect(page).to have_text("The following POMs have been allocated to this case")
      expect(page).to have_text("Fred")
    end
  end

  context 'with 2 previous poms' do
    let(:other) { build(:pom) }
    let(:poms) { [pom, other] }

    let(:recent_pom_history) do
      [
        { name: 'FRED', started_at: Time.zone.now, ended_at: Time.zone.now },
        { name: 'BARNEY', started_at: Time.zone.now, ended_at: Time.zone.now }
      ]
    end

    it 'says they have been assigned' do
      expect(page).to have_text("The following POMs have been allocated to this case")
      expect(page).to have_text("Fred")
      expect(page).to have_text("Barney")
    end
  end

  context 'with 3 previous poms' do
    let(:other) { build(:pom) }
    let(:other2) { build(:pom) }
    let(:poms) { [pom, other, other2] }

    let(:recent_pom_history) do
      [
        { name: 'FRED', started_at: Time.zone.now, ended_at: Time.zone.now },
        { name: 'BARNEY', started_at: Time.zone.now, ended_at: Time.zone.now },
        { name: 'WILMER', started_at: Time.zone.now, ended_at: Time.zone.now }
      ]
    end

    it 'says they have been assigned' do
      expect(page).to have_text("The following POMs have been allocated to this case")
      expect(page).to have_text("Fred")
      expect(page).to have_text("Barney")
      expect(page).to have_text("Wilmer")
    end
  end
end
