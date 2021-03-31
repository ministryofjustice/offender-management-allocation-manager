# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "female_allocations/index", type: :view do
  before do
    stub_auth_token
    stub_poms(prison.code, poms)
    stub_offenders_for_prison(prison.code, [])

    assign(:prison, prison)
    assign(:previous_poms, poms.map { |p| StaffMember.new(prison, p.staff_id) })
    assign(:prisoner, offender)
    assign(:case_info, case_info)
    assign(:probation_poms, poms.map { |p| StaffMember.new(prison, p.staff_id) })
    assign(:prison_poms, [])
    render
  end

  let(:case_info) { build(:case_information) }
  let(:offender) { build(:offender, offenderNo: case_info.nomis_offender_id).tap { |o| o.load_case_information(case_info) } }
  let(:prison) { build(:prison) }
  let(:pom) { build(:pom) }
  let(:page) { Nokogiri::HTML(rendered) }

  context 'with 1 previous pom' do
    let(:poms) { [pom] }

    it 'says they have been assigned' do
      expect(page).to have_text("#{pom.first_name} #{pom.last_name} has previously been allocated to this case")
    end

    it 'links up the previous POM' do
      expect(page.css('.pom_name')).to have_text('Previously allocated to case')
    end
  end

  context 'with 2 previous poms' do
    let(:other) { build(:pom) }
    let(:poms) { [pom, other] }

    it 'says they have been assigned' do
      expect(page).to have_text("#{pom.first_name} #{pom.last_name} and #{other.first_name} #{other.last_name} have previously been allocated to this case")
    end
  end

  context 'with 3 previous poms' do
    let(:other) { build(:pom) }
    let(:other2) { build(:pom) }
    let(:poms) { [pom, other, other2] }

    it 'says they have been assigned' do
      expect(page).to have_text("#{pom.first_name} #{pom.last_name}, #{other.first_name} #{other.last_name}, and #{other2.first_name} #{other2.last_name} have previously been allocated to this case")
    end
  end
end
