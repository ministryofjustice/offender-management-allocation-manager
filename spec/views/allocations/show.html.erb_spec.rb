# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "allocations/show", type: :view do
  let(:prison) { build(:prison) }
  let(:page) { Nokogiri::HTML(rendered) }
  let(:next_year) { (Time.zone.today + 1.year).year }
  let(:api_offender) do
    build(:hmpps_api_offender,
          sentence: attributes_for(:sentence_detail, conditionalReleaseDate: Date.new(next_year + 1, 1, 28)))
  end
  let(:case_info) { build(:case_information, :crc) }
  let(:offender) { build(:mpc_offender, prison: prison, offender: case_info.offender, prison_record: api_offender) }

  before do
    assign(:prison, prison)
    assign(:pom, build(:pom))
    assign(:prisoner, offender)
    assign(:allocation, create(:allocation_history, prison: build(:prison).code))
    assign(:keyworker, build(:keyworker))
    render
  end

  it 'shows handover dates' do
    expect(page.css('#handover-start-date-row')).to have_text('Handover start date')
    expect(page.css('#handover-start-date-row')).to have_text("05 Nov #{next_year}")

    expect(page.css('#responsibility-handover-date-row')).to have_text('Responsibility handover')
    expect(page.css('#responsibility-handover-date-row')).to have_text("05 Nov #{next_year}")
  end

  describe 'category label' do
    let(:key) { page.css('#offender-category > td:nth-child(1)').text }
    let(:value) { page.css('#offender-category > td:nth-child(2)').text }

    context 'when a male offender category' do
      let(:api_offender) { build(:hmpps_api_offender, category: build(:offender_category, :cat_d)) }

      it 'shows the category label' do
        expect(key).to eq('Category')
        expect(value).to eq('Cat D')
      end
    end

    context 'when a female offender category' do
      let(:api_offender) { build(:hmpps_api_offender, category: build(:offender_category, :female_open)) }

      it 'shows the category label' do
        expect(key).to eq('Category')
        expect(value).to eq('Female Open')
      end
    end

    context 'when category is unknown' do
      # This happens when an offender's category assessment hasn't been completed yet
      let(:api_offender) { build(:hmpps_api_offender, category: nil) }

      it 'shows "Unknown"' do
        expect(key).to eq('Category')
        expect(value).to eq('Unknown')
      end
    end
  end

  describe 'with mocking' do
    let(:nomis_offender_id) { FactoryBot.generate :nomis_offender_id }

    before do
      allow(offender).to receive_messages(
        pom_responsible?: true,
        com_responsible?: false,
        pom_supporting?: true,
        responsibility_override?: false,
      )
      stub_template 'shared/_badges.html.erb' => ''
      allow(view).to receive(:vlo_tag).and_return('')
      allow(view).to receive(:prisoner_location).and_return('')
      assign(:prisoner, offender)
    end

    describe 'responsibility' do
      it 'allows POM responsible cases to have responsibility overridden' do
        render
        expect(page).to have_css ".responsibility_change a[href='#{new_prison_responsibility_path(prison.code, nomis_offender_id: offender.offender_no)}']"
      end

      it 'allows COM responsible overrides to be deleted' do
        allow(offender).to receive_messages(
          pom_responsible?: false,
          com_responsible?: true,
          responsibility_override?: true,
        )
        render
        expect(page).to have_css ".responsibility_change a[href='#{confirm_removal_prison_responsibility_path(prison.code, nomis_offender_id: offender.offender_no)}']"
      end
    end
  end
end
