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

  context 'when on the caseload tab' do
    let(:case_info) { create(:case_information) }
    let(:api_offender) { build(:hmpps_api_offender, prisonerNumber: case_info.nomis_offender_id) }
    let(:offender) { build(:mpc_offender, prison_record: api_offender, offender: case_info.offender, prison: prison) }
    let(:allocations) { [build(:allocation_history, nomis_offender_id: case_info.nomis_offender_id, secondary_pom_nomis_id: pom.staff_id)] }

    let(:first_offender_row) do
      row = page.css('td').map(&:text).map(&:strip)
      # The first column is offender name and number underneath each other - just grab the non-blank data
      split_col_zero = row.first.split("\n").map(&:strip).reject(&:empty?)
      # remove new lines and repeating whitespace
      row.each do |r|
        r.delete!("\n")
        r.squeeze!(" ")
      end
      [split_col_zero] + row[1..]
    end
    let(:tabname) { 'caseload' }
    let(:offenders) { [offender] }

    it 'displays correct headers' do
      expect(page.css('th a').map(&:text).map(&:strip)).to eq(["Case", "Role", "Location", "Earliest release date", "Tier", "Allocation date"])
    end

    it 'displays correct data' do
      expect(first_offender_row)
        .to eq [
          [offender.full_name, case_info.nomis_offender_id],
          "Co-working",
          offender.location,
          "#{offender.earliest_release[:type]} : #{offender.earliest_release[:date].to_s(:rfc822)}",
          case_info.tier,
          Time.zone.today.to_s(:rfc822),
        ]
    end
  end
end
