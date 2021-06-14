# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "allocations/show", type: :view do
  let(:page) { Nokogiri::HTML(rendered) }
  let(:next_year) { (Time.zone.today + 1.year).year }
  let(:offender) {
    build(:hmpps_api_offender,
          sentence: build(:sentence_detail, conditionalReleaseDate: Date.new(next_year + 1, 1, 28)))
  }

  before do
    assign(:prison, create(:prison))
    assign(:pom, build(:pom))
    assign(:prisoner, offender)
    assign(:allocation, create(:allocation_history))
    assign(:keyworker, build(:keyworker))
    assign(:case_info, build(:case_information))
    render
  end

  it 'shows handover dates' do
    expect(page.css('#handover-start-date-row')).to have_text('Handover start date')
    expect(page.css('#handover-start-date-row')).to have_text("05/11/#{next_year}")

    expect(page.css('#responsibility-handover-date-row')).to have_text('Responsibility handover')
    expect(page.css('#responsibility-handover-date-row')).to have_text("05/11/#{next_year}")
  end

  describe 'category label' do
    let(:key) { page.css('#offender-category > td:nth-child(1)').text }
    let(:value) { page.css('#offender-category > td:nth-child(2)').text }

    context 'when a male offender category' do
      let(:offender) { build(:hmpps_api_offender, category: build(:offender_category, :cat_d)) }

      it 'shows the category label' do
        expect(key).to eq('Category')
        expect(value).to eq('Cat D')
      end
    end

    context 'when a female offender category' do
      let(:offender) { build(:hmpps_api_offender, category: build(:offender_category, :female_open)) }

      it 'shows the category label' do
        expect(key).to eq('Category')
        expect(value).to eq('Female Open')
      end
    end

    context 'when category is unknown' do
      # This happens when an offender's category assessment hasn't been completed yet
      let(:offender) { build(:hmpps_api_offender, category: nil) }

      it 'shows "Unknown"' do
        expect(key).to eq('Category')
        expect(value).to eq('Unknown')
      end
    end
  end
end
