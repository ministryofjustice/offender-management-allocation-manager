require 'rails_helper'

describe HmppsApi::PrisonApi::MovementApi do
  describe 'Movements for date' do
    it 'can get movements on a specific date',
       vcr: { cassette_name: 'prison_api/movement_api_on_date' } do
      movements = described_class.movements_on_date(Date.iso8601('2019-02-20'))

      expect(movements).to be_a(Array)
      expect(movements.length).to eq(2)
      expect(movements).to all be_a(HmppsApi::Movement)
    end
  end

  it 'can get movements for a specific_offender',
     vcr: { cassette_name: 'prison_api/movement_api_for_offender' } do
    timeline = described_class.movements_for('A5019DY')
    expect(timeline.prison_episode(Date.new 2019, 1, 23).prison_code).to eq('DTI')
  end

  describe 'Movements for single offenders' do
    let(:prison) { build(:prison) }

    it 'sort movements (oldest first) for a specific_offender' do
      allow_any_instance_of(HmppsApi::Client).to receive(:post).and_return([
        attributes_for(:movement, offenderNo: '2', toAgency: build(:prison).code, movementDate: '2017-03-09').stringify_keys,
        attributes_for(:movement, offenderNo: '1', toAgency: prison.code, movementDate: '2015-01-01').stringify_keys
      ])

      timeline = described_class.movements_for('A5019DY')
      expect(timeline.prison_episode(Date.new 2016, 1, 23).prison_code).to eq(prison.code)
    end

    it 'can return multiple movements for a specific offender',
       vcr: { cassette_name: 'prison_api/movement_api_multiple_movements' } do
      timeline = described_class.movements_for('G1670VU')
      expect(timeline.prison_episode(Date.new 2017, 1, 23).prison_code).to eq('DNI')
    end
  end
end
