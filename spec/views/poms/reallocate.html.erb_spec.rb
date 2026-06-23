# frozen_string_literal: true

require 'rails_helper'

RSpec.describe 'poms/reallocate', type: :view do
  let(:prison) { create(:prison) }
  let(:pom_record) { build(:pom, :prison_officer, staffId: 10_001, firstName: 'John', lastName: 'Doe') }
  let(:pom) { StaffMember.new(prison, pom_record.staff_id) }

  before do
    stub_poms(prison.code, [pom_record])
    stub_offenders_for_prison(prison.code, offenders)

    view.request.path_parameters[:prison_id] = prison.code
    view.request.path_parameters[:nomis_staff_id] = pom_record.staff_id

    assign(:prison, prison)
    assign(:pom, pom)
    assign(:summary, {
      last_allocated_date: 1.day.ago.to_date,
      last_seven_days: 1,
      release_next_four_weeks: 0,
    })
  end

  context 'when the POM has coworking allocations' do
    let(:offenders) { build_list(:nomis_offender, 3) }

    before do
      offenders.each do |offender|
        offender_no = offender.fetch(:prisonerNumber)
        create(:case_information, offender: build(:offender, nomis_offender_id: offender_no))
      end

      # 2 primary allocations
      create(:allocation_history, prison: prison.code,
                                  nomis_offender_id: offenders[0].fetch(:prisonerNumber),
                                  primary_pom_nomis_id: pom_record.staff_id)
      create(:allocation_history, prison: prison.code,
                                  nomis_offender_id: offenders[1].fetch(:prisonerNumber),
                                  primary_pom_nomis_id: pom_record.staff_id)

      # 1 coworking allocation
      create(:allocation_history, prison: prison.code,
                                  nomis_offender_id: offenders[2].fetch(:prisonerNumber),
                                  primary_pom_nomis_id: 99_999,
                                  secondary_pom_nomis_id: pom_record.staff_id,
                                  secondary_pom_name: 'Doe, John')

      render
    end

    it 'shows the coworker cases count' do
      expect(rendered).to include('Coworker cases')
      expect(rendered).to include('1')
    end
  end

  context 'when the POM has no coworking allocations' do
    let(:offenders) { build_list(:nomis_offender, 1) }

    before do
      offender_no = offenders[0].fetch(:prisonerNumber)
      create(:case_information, offender: build(:offender, nomis_offender_id: offender_no))
      create(:allocation_history, prison: prison.code,
                                  nomis_offender_id: offender_no,
                                  primary_pom_nomis_id: pom_record.staff_id)

      render
    end

    it 'shows the coworker cases row with zero' do
      expect(rendered).to include('Coworker cases')
    end
  end
end
