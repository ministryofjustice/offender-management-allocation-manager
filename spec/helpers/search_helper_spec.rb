require 'rails_helper'

RSpec.describe SearchHelper do
  describe 'the CTA' do
    context 'with no allocation' do
      let(:offender) {
        build(:offender).tap { |o|
          o.load_case_information(build(:case_information, tier: 'A'))
        }
      }
      let(:expected_link) {
        link_to 'Allocate', prison_prisoner_staff_index_path('LEI', prisoner_id: offender.offender_no)
      }

      it "will change to allocate if there is no allocation" do
        expect(cta_for_offender('LEI', offender)).to eq(expected_link)
      end
    end

    context 'with an allocation' do
      let(:case_info) { build(:case_information, tier: 'A') }
      let(:offender) {
        build(:offender, offenderNo: case_info.nomis_offender_id).tap { |o|
          o.allocated_pom_name = 'Bob'
          o.load_case_information(case_info)
        }
      }

      it "will change to view" do
        text, _link = cta_for_offender('LEI', offender)
        expect(text).to eq("<a href=\"/prisons/LEI/allocations/#{offender.offender_no}\">View</a>")
      end
    end
  end
end
