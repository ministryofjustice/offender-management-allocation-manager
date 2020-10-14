# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "allocations/show", type: :view do
  before do
    assign(:prison, build(:prison))
    assign(:pom, build(:pom))
    assign(:prisoner, build(:offender))
    assign(:allocation, build(:allocation))
    assign(:keyworker, build(:keyworker))
    render
  end

  let(:page) { Nokogiri::HTML(rendered) }

  it 'shows handover dates' do
    expect(page.css('#handover-start-date-row')).to have_text('Handover start date')
    expect(page.css('#handover-start-date-row')).to have_text('05/11/2021')

    expect(page.css('#responsibility-handover-date-row')).to have_text('Responsibility handover')
    expect(page.css('#responsibility-handover-date-row')).to have_text('05/11/2021')
  end
end
