# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "allocations/new", type: :view do
  before do
    assign(:prison, build(:prison))
    assign(:prisoner, OffenderPresenter.new(build(:offender)))
    assign(:previously_allocated_pom_ids, [])
    assign(:recommended_poms, [])
    assign(:not_recommended_poms, [])
    assign(:unavailable_pom_count, 0)
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
