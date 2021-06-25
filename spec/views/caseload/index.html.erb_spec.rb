# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "caseload/index", type: :view do
  before do
    assign(:pending_task_count, 0)
    assign(:allocations,
           Kaminari::paginate_array(offenders).page(1))
    assign(:new_cases_count, 0)
    assign(:pending_handover_count, offenders.count)
    assign(:pom, StaffMember.new(prison, staff_id))
    assign(:prison, prison)
    assign(:staff_id, staff_id)
  end

  let(:staff_id) { build(:pom).staff_id }
  let(:page) { Nokogiri::HTML(rendered) }

  context 'with a caseload' do
    let(:offender_objects) {
      [
        build(:hmpps_api_offender).tap do |o|
          o.load_case_information(build(:case_information))
        end
      ]
    }

    let(:offenders) {
      offender_objects.map do |o|
        AllocatedOffender.new(staff_id, build(:allocation_history, nomis_offender_id: o.offender_no, primary_pom_allocated_at: DateTime.now.utc), o)
      end
    }

    context 'with a male prison' do
      before do
        render
      end

      let(:prison) { create(:prison) }
      let(:first_offender_row) {
        row = page.css('td').map(&:text).map(&:strip)
        # The first column is offender name and number underneath each other - just grab the non-blank data
        split_col_zero = row.first.split("\n").map(&:strip).reject(&:empty?)
        [split_col_zero] + row[1..]
      }

      it 'displays caseload' do
        expect(page).to have_content 'Your caseload'
      end

      it 'displays correct headers' do
        expect(page.css('th a').map(&:text).map(&:strip)).to eq(["Case", "Location", "Tier", "Earliest release date", "Allocationdate", "Role"])
      end

      it 'displays correct data' do
        expect(first_offender_row).
          to eq [
                  [offenders.first.full_name, offenders.first.offender_no],
                  "N/A",
                  offenders.first.tier,
                  offenders.first.earliest_release_date.to_s(:rfc822),
                  Time.zone.today.to_s(:rfc822),
                  "Co-working"
                ]
      end
    end

    context 'with a female prison' do
      let(:prison) { create(:womens_prison) }

      before do
        render
      end

      it 'displays caseload' do
        expect(page).to have_content 'Your caseload'
        expect(page).to have_content 'Medium'
      end

      it 'displays correct headers' do
        expect(page.css('th a').map(&:text).map(&:strip)).to eq(["Prisoner name", "Location", "Tier", "Complexity level", "Earliest release date", "Role"])
      end
    end
  end

  context 'with no caseload' do
    before do
      render
    end

    let(:offenders) { [] }
    let(:prison) { create(:prison) }

    it 'displays an empty page' do
      expect(page).to have_content 'No allocated cases'
    end
  end
end
