# frozen_string_literal: true

require 'rails_helper'

RSpec.describe "poms/show", type: :view do
  let(:page) { Nokogiri::HTML(rendered) }
  let(:prison) { create(:prison) }
  let(:pom) { build(:pom) }
  let(:offenders) {
    [build(:nomis_offender, sentence: attributes_for(:sentence_detail, releaseDate: Time.zone.today + 2.weeks)),
     build(:nomis_offender, sentence: attributes_for(:sentence_detail, releaseDate: Time.zone.today + 5.weeks)),
     build(:nomis_offender, sentence: attributes_for(:sentence_detail, releaseDate: Time.zone.today + 8.weeks))]
  }
  let(:offender_nos) { offenders.map  { |o| o.fetch(:offenderNo) } }
  let(:summary_rows) { page.css('.govuk-summary-list__row') }
  let(:two_days_ago) { Time.zone.today - 2.days }

  before do
    stub_auth_token
    stub_poms prison.code, [pom]
    stub_offenders_for_prison prison.code, offenders
    assign :prison, prison
    assign :pom, StaffMember.new(prison, pom.staff_id)

    create(:case_information, offender: build(:offender, nomis_offender_id: offender_nos.first))
    create(:allocation_history, prison: prison.code, nomis_offender_id: offender_nos.first, primary_pom_nomis_id: pom.staff_id, primary_pom_allocated_at: Time.zone.today - 3.days)

    create(:case_information, offender: build(:offender, nomis_offender_id: offender_nos.second))
    # Yes this line doesn't make sense. But the code cannot (easily/at all) work out the allocation date for co-working - so let's not try that hard until allocation data is fixed
    create(:allocation_history, prison: prison.code, nomis_offender_id: offender_nos.second, secondary_pom_nomis_id: pom.staff_id, primary_pom_allocated_at: two_days_ago)

    create(:case_information, offender: build(:offender, nomis_offender_id: offender_nos.third))
    create(:allocation_history, prison: prison.code, nomis_offender_id: offender_nos.third, primary_pom_nomis_id: pom.staff_id,
           updated_at: Time.zone.today - 8.days, primary_pom_allocated_at: Time.zone.today - 8.days)

    render
  end

  context 'when on the overview tab' do
    it 'shows working pattern' do
      expect(summary_rows.first).to have_content('Working pattern')
    end

    it 'shows last case allocated date' do
      expect(summary_rows[2]).to have_content(two_days_ago.to_s(:rfc822))
    end

    it 'shows allocations in last 7 days' do
      expect(summary_rows[3]).to have_content(2)
    end

    it 'shows releases due in next 4 weeks' do
      expect(summary_rows[4]).to have_content(1)
    end
  end
end
