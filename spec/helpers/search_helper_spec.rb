require 'rails_helper'

RSpec.describe SearchHelper do
  describe 'the CTA' do
    context 'with no tier' do
      let(:offender) { build(:offender) }

      it "will change to edit if there is no tier" do
        offender = build(:offender)
        text, _link = cta_for_offender('LEI', offender)
        expect(text).to eq("<a href=\"/prisons/LEI/case_information/new/#{offender.offender_no}\">Edit</a>")
      end
    end

    context 'with no allocation' do
      let(:offender) {
        build(:offender).tap { |o|
          o.load_case_information(build(:case_information, tier: 'A'))
        }
      }

      it "will change to allocate if there is no allocation" do
        text, _link = cta_for_offender('LEI', offender)
        expect(text).to eq("<a href=\"/prisons/LEI/allocations/#{offender.offender_no}/new\">Allocate</a>")
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
