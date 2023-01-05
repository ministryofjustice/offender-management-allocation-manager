require 'rails_helper'
require 'cnl_deactivation'

RSpec.describe CnlDeactivation do
  let(:prison) { create(:womens_prison) }
  let(:offender_id) { 'A0000BC' }
  let(:nomis_offender) { build(:nomis_offender, prisonerNumber: offender_id).with_indifferent_access }

  let(:api_offender) do
    HmppsApi::Offender.new(offender: nomis_offender, category: nil, latest_temp_movement: nil, complexity_level: 'high')
  end

  before do
    allow_any_instance_of(Prison).to receive(:offenders).and_return(
      [
        MpcOffender.new(prison: prison, offender: Offender.new(nomis_offender_id: offender_id), prison_record: api_offender),
        MpcOffender.new(prison: prison, offender: Offender.new(nomis_offender_id: offender_id), prison_record: api_offender)
      ]
    )

    allow_any_instance_of(HmppsApi::Offender).to receive(:sentenced?).and_return(is_sentenced)
    allow(HmppsApi::PrisonApi::OffenderApi).to receive(:get_offender).and_return(api_offender)
    allow(HmppsApi::ComplexityApi).to receive(:inactivate).and_return(nil)
  end

  describe '#call' do
    before { described_class.new(dry_run: false).call }

    context 'with a sentenced offender' do
      let(:is_sentenced) { true }

      it 'does not send inactivate to complexity of need microservice' do
        expect(HmppsApi::ComplexityApi).not_to have_received(:inactivate).with(offender_id)
      end
    end

    context 'with an unsentenced offender' do
      let(:is_sentenced) { false }

      it 'sends inactivate to complexity of need microservice' do
        expect(HmppsApi::ComplexityApi).to have_received(:inactivate).twice.with(offender_id)
      end
    end
  end
end
