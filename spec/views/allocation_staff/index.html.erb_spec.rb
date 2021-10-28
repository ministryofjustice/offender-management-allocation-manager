# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "allocation_staff/index", type: :view do
  let(:next_year) { (Time.zone.today + 1.year).year }
  let(:case_info) { build(:case_information, :crc) }
  let(:api_offender) {
    build(:hmpps_api_offender,
          sentence: attributes_for(:sentence_detail, conditionalReleaseDate: Date.new(next_year + 1, 1, 28)),
          prisonerNumber: case_info.nomis_offender_id)
  }
  let(:offender) { build(:mpc_offender, prison: prison, offender: case_info.offender, prison_record: api_offender) }
  let(:prison) { create(:prison) }
  let(:pom) { build(:pom) }
  let(:page) { Nokogiri::HTML(rendered) }

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

  context 'without poms' do
    let(:poms) { [] }

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
  end
end
