# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "poms/show", type: :view do
  let(:page) { Nokogiri::HTML(rendered) }
  let(:prison) { create(:prison) }
  let(:pom) { build(:pom) }
  let(:offender_nos) { offenders.map(&:offender_no) }
  let(:summary_rows) { page.css('.govuk-summary-list__row') }
  let(:two_days_ago) { Time.zone.today - 2.days }

  before do
    stub_auth_token
    stub_poms prison.code, [pom]

    assign :prison, prison
    assign :pom, StaffMember.new(prison, pom.staff_id)
    assign :tab, tabname

    assign(:allocations, offenders.zip(allocations).map do |offender, allocation|
      AllocatedOffender.new(pom.staff_id,
                            allocation,
                            offender)
    end)

    # stub POM offenders to prevent API call on the view
    stub_offenders_for_prison(prison.code, [])

    assign(:summary, {
      all_prison_cases: allocations.count,
      new_cases_count: allocations.count,
      total_cases: allocations.count,
      last_seven_days: allocations.count { |a| a.primary_pom_allocated_at.to_date >= 7.days.ago },
      release_next_four_weeks: 1,
      pending_handover_count: 42,
      in_progress_handover_count: 0,
      pending_task_count: 0,
      last_allocated_date: allocations.max_by(&:primary_pom_allocated_at)&.primary_pom_allocated_at&.to_date
    })

    render
  end

  context 'when on the overview tab' do
    let!(:allocations) do
      [
        create(:allocation_history, prison: prison.code, nomis_offender_id: offender_nos.first,
                                    primary_pom_nomis_id: pom.staff_id, primary_pom_allocated_at: Time.zone.today - 3.days),
        # Yes this line doesn't make sense. But the code cannot (easily/at all) work out the allocation date for co-working - so let's not try that hard until allocation data is fixed
        create(:allocation_history, prison: prison.code, nomis_offender_id: offender_nos.second,
                                    secondary_pom_nomis_id: pom.staff_id, primary_pom_allocated_at: two_days_ago),

        create(:allocation_history, prison: prison.code, nomis_offender_id: offender_nos.third,
                                    primary_pom_nomis_id: pom.staff_id,
                                    updated_at: Time.zone.today - 8.days, primary_pom_allocated_at: Time.zone.today - 8.days),

        # add an allocation for an indeterminate with no release date
        create(:allocation_history, prison: prison.code, nomis_offender_id: offender_nos.fourth,
                                    primary_pom_nomis_id: pom.staff_id,
                                    updated_at: Time.zone.today - 8.days, primary_pom_allocated_at: Time.zone.today - 8.days)
      ]
    end
    let(:api_one) { build(:hmpps_api_offender, sentence: attributes_for(:sentence_detail, releaseDate: Time.zone.today + 2.weeks)) }
    let(:api_two) { build(:hmpps_api_offender, sentence: attributes_for(:sentence_detail, releaseDate: Time.zone.today + 5.weeks)) }
    let(:api_three) { build(:hmpps_api_offender, sentence: attributes_for(:sentence_detail, releaseDate: Time.zone.today + 8.weeks)) }
    let(:api_four) { build(:hmpps_api_offender, sentence: attributes_for(:sentence_detail, :indeterminate)) }
    let(:offenders) do
      [api_one, api_two, api_three, api_four].map do |api_offender|
        build(:mpc_offender, prison_record: api_offender, offender: build(:case_information).offender, prison: prison)
      end
    end
    let(:tabname) { 'overview' }

    it 'shows working pattern' do
      expect(summary_rows[3]).to have_content('Working pattern')
    end

    it 'shows last case allocated date' do
      expect(summary_rows.first).to have_content(two_days_ago.to_s(:rfc822))
    end

    it 'shows allocations in last 7 days' do
      expect(summary_rows[1]).to have_content(2)
    end

    it 'shows releases due in next 4 weeks' do
      expect(summary_rows[2]).to have_content(1)
    end
  end
end
