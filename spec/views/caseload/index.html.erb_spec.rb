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
    render
  end

  let(:prison) { build(:prison) }
  let(:staff_id) { build(:pom).staff_id }
  let(:page) { Nokogiri::HTML(rendered) }

  context 'with a caseload' do
    let(:offenders) {
      [
          AllocatedOffender.new(staff_id, build(:allocation), build(:offender_summary))
      ]
    }

    it 'displays caseload' do
      expect(page).to have_content 'Your caseload'
    end
  end

  context 'with no caseload' do
    let(:offenders) { [] }

    it 'displays an empty page' do
      expect(page).to have_content 'No allocated cases'
    end
  end
end
