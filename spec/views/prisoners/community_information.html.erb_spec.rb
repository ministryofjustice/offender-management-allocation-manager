require 'rails_helper'

RSpec.describe "prisoners/community_information", type: :view do
  let(:page) { Nokogiri::HTML(rendered) }

  let(:offender) do
    build(:offender, :determinate, latestLocationId: 'LEI', offenderNo: 'G8060UF',
          sentence: build(:sentence_detail,
                          sentenceStartDate: Time.zone.today - 11.months,
                          conditionalReleaseDate: Time.zone.today + 8.months,
                          automaticReleaseDate: Time.zone.today + 8.months,
                          releaseDate: Time.zone.today + 8.months,
                          tariffDate: nil))
  end

  before do
    allow(OffenderService).to receive(:get_offender).and_return(offender)
  end

  context 'when there is no COM error' do
    let(:case_info) do
      create(:case_information, nomis_offender_id: offender.offender_no,
             team: build(:team, local_divisional_unit: build(:local_divisional_unit)))
    end

    before do
      offender.load_case_information(case_info)
      assign(:prisoner, OffenderPresenter.new(offender))
      render partial: 'prisoners/community_information'
    end

    it 'does not apply css error highlighting on the COM name row' do
      expect(page).not_to have_css(".govuk-table__cell-error")
      expect(page).not_to have_css(".govuk-table__cell-error-value")
    end
  end

  context 'when there is a COM error' do
    let(:case_info) do
      create(:case_information, nomis_offender_id: offender.offender_no,
             team: build(:team, local_divisional_unit: build(:local_divisional_unit, email_address: nil)))
    end

    before do
      offender.load_case_information(case_info)
      assign(:prisoner, OffenderPresenter.new(offender))
      render partial: 'prisoners/community_information'
    end


    it 'applies css error highlighting the COM field' do
      expect(page).to have_css(".govuk-table__cell-error")
      expect(page).to have_css(".govuk-table__cell-error-value")
    end
  end
end
