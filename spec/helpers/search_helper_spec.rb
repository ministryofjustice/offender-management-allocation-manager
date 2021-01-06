require 'rails_helper'

RSpec.describe SearchHelper do
  describe 'the CTA' do
    it "will change to edit if there is no tier" do
      offender = HmppsApi::Offender.new(
        offender_no: 'A'
      )
      text, _link = cta_for_offender('LEI', offender)
      expect(text).to eq('<a href="/prisons/LEI/case_information/new/A">Edit</a>')
    end

    it "will change to allocate if there is no allocation" do
      offender = HmppsApi::Offender.new(
        offender_no: 'A').tap { |o|
        o.load_case_information(build(:case_information, tier: 'A'))
      }
      text, _link = cta_for_offender('LEI', offender)
      expect(text).to eq('<a href="/prisons/LEI/allocations/A/new">Allocate</a>')
    end

    context 'with an allocation' do
      let(:case_info) { build(:case_information, tier: 'A') }

      it "will change to view" do
        offender = HmppsApi::Offender.new(
          offender_no: 'G1234FX'
        ).tap { |o|
          o.allocated_pom_name = 'Bob'
          o.load_case_information(case_info)
        }

        text, _link = cta_for_offender('LEI', offender)
        expect(text).to eq('<a href="/prisons/LEI/allocations/G1234FX">View</a>')
      end
    end
  end
end
