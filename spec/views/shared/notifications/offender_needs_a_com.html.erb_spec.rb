require 'rails_helper'

RSpec.describe "shared/notifications/offender_needs_a_com", type: :view do
  let(:case_info) { build(:case_information, enhanced_resourcing: true, local_delivery_unit: ldu, manual_entry: ldu.nil?) }
  let(:ldu) { build(:local_delivery_unit) }
  let(:prison) { build(:prison) }

  let(:offender) { build(:mpc_offender, prison: prison, offender: case_info.offender, prison_record: api_offender) }
  let(:api_offender) do
    build(:hmpps_api_offender, sentence: attributes_for(:sentence_detail, :determinate, :after_handover))
  end

  before do
    render partial: 'shared/notifications/offender_needs_a_com', locals: { offender: offender }
  end

  context 'when we know the LDU details' do
    it 'includes the LDU details' do
      expect(rendered).to include(ldu.name)
      expect(rendered).to include(ldu.email_address)
    end
  end

  context 'when we do not know the LDU details' do
    let(:ldu) { nil }

    it 'does not show the LDU details' do
      expect(rendered).to include('We do not know which LDU will be responsible for this person')
    end
  end
end
