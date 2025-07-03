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
  let(:page) { Nokogiri::HTML(rendered) }

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
    render
  end

  context 'with 1 previous pom' do
    let(:poms) { [pom] }

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
