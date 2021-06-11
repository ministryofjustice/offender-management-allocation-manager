require 'rails_helper'

RSpec.describe "prisoners/community_information", type: :view do
  let(:page) { Nokogiri::HTML(rendered) }
  let(:prison) { build(:prison) }

  let(:case_info) { build(:case_information) }

  let(:api_offender) {
    build(:hmpps_api_offender).tap { |o|
      o.sentence = build(:sentence_detail, :inside_handover_window)
    }
  }
  let(:offender) { build(:mpc_offender, prison: prison, offender: case_info.offender, prison_record: api_offender) }

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
