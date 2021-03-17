# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "female_allocations/new", type: :view do
  before do
    stub_auth_token
    stub_poms(prison.code, [pom])
    stub_offenders_for_prison(prison.code, [])

    assign(:prison, prison)
    assign(:previous_poms, [pom].map { |p| StaffMember.new(prison, p.staff_id) })
    assign(:prisoner, build(:offender))
    assign(:probation_poms, [pom].map { |p| StaffMember.new(prison, p.staff_id) })
    assign(:prison_poms, [])
    render
  end

  let(:prison) { build(:prison) }
  let(:pom) { build(:pom) }
  let(:page) { Nokogiri::HTML(rendered) }

  it 'links up the previous POM' do
    expect(page.css('.pom_name')).to have_text('Previously allocated to case')
  end
end
