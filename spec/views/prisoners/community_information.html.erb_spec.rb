require 'rails_helper'

RSpec.describe "prisoners/community_information", type: :view do
  let(:page) { Nokogiri::HTML(rendered) }

  let(:case_info) { build(:case_information) }

  let(:offender) {
    build(:hmpps_api_offender).tap { |o|
      o.load_case_information(case_info)
      o.sentence = build(:sentence_detail, :inside_handover_window)
    }
  }

  before do
    assign(:prisoner, offender)
    render partial: 'prisoners/community_information'
  end

  context 'when there is no COM but one is needed' do
    it 'applies CSS error highlighting on the COM name row' do
      expect(page).to have_css(".govuk-table__cell-error")
      expect(page).to have_css(".govuk-table__cell-error-value")
    end
  end

  context 'when a COM is needed, and one is allocated' do
    let(:case_info) { build(:case_information, :with_com) }

    it 'applies css error highlighting the COM field' do
      expect(page).not_to have_css(".govuk-table__cell-error")
      expect(page).not_to have_css(".govuk-table__cell-error-value")
    end
  end
end
