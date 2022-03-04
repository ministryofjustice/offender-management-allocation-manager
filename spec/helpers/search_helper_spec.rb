require 'rails_helper'

RSpec.describe SearchHelper do
  let(:prison) { build(:prison) }

  describe 'the CTA' do
    context 'with no allocation' do
      let(:api_offender) { build(:hmpps_api_offender) }
      let(:offender) do
        x = build(:mpc_offender, prison: prison, offender: build(:case_information, tier: 'A').offender, prison_record: api_offender)
        OffenderWithAllocationPresenter.new(x, nil)
      end
      let(:expected_link) do
        link_to 'Allocate', prison_prisoner_staff_index_path('LEI', prisoner_id: offender.offender_no)
      end

      it "will change to allocate if there is no allocation" do
        expect(cta_for_offender('LEI', offender)).to eq(expected_link)
      end
    end

    context 'with an allocation' do
      let(:case_info) { build(:case_information, tier: 'A') }
      let(:api_offender) { build(:hmpps_api_offender) }
      let(:offender) do
        x = build(:mpc_offender, prison: prison, offender: case_info.offender, prison_record: api_offender)
        OffenderWithAllocationPresenter.new(x, build(:allocation_history))
      end

      it "will change to view" do
        text, _link = cta_for_offender('LEI', offender)
        expect(text).to eq(link_to 'View', prison_prisoner_allocation_path('LEI', offender.offender_no))
      end
    end
  end
end
