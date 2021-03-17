# frozen_string_literal: true

require 'rails_helper'

RSpec.describe FemaleAllocationsController, type: :controller do
  let(:prison) { build(:womens_prison) }
  let(:pom) { build(:pom) }
  let(:offender) { build(:nomis_offender) }
  let(:prisoner_id) { offender.fetch(:offenderNo) }

  before do
    stub_poms(prison.code, [pom])
    stub_offender(offender)

    stub_sso_data(prison.code)
  end

  describe '#new' do
    before do
      create(:case_information, nomis_offender_id: prisoner_id)
      a = create(:allocation, nomis_offender_id: prisoner_id, primary_pom_nomis_id: pom.staff_id)
      a.deallocate_offender_after_release
    end

    it 'retrives old POMs' do
      get :new, params: { prison_id: prison.code, prisoner_id: prisoner_id }
      expect(assigns(:previous_poms).map(&:staff_id)).to eq [pom.staff_id]
    end
  end
end
