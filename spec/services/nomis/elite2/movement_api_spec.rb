require 'rails_helper'

describe Nomis::Elite2::MovementApi do
  describe 'Movements for date' do
    it 'can get movements on a specific date',
       vcr: { cassette_name: :movement_api_on_date } do
      movements = described_class.movements_on_date(Date.iso8601('2019-02-20'))

      expect(movements).to be_kind_of(Array)
      expect(movements.length).to eq(2)
      expect(movements.first).to be_kind_of(Nomis::Movement)
    end
  end

  describe 'Movements for single offenders' do
    it 'can get movements for a specific_offender',
       vcr: { cassette_name: :movement_api_for_offender } do
      movements = described_class.movements_for('A5019DY')

      expect(movements).to be_kind_of(Array)
      expect(movements.length).to eq(2)
      expect(movements.first).to be_kind_of(Nomis::Movement)
    end

    it 'sort movements (oldest first) for a specific_offender' do
      allow_any_instance_of(Nomis::Client).to receive(:post).and_return([
        {
          'offenderNo' => '2',
          'createDateTime' => '2017-03-09T15:50:52.676892'
        },
        {
          'offenderNo' => '1',
          'createDateTime' => '2015-01-01T15:50:52.676892'
        }
      ])

      movements = described_class.movements_for('A5019DY')

      expect(movements).to be_kind_of(Array)
      expect(movements.length).to eq(2)
      expect(movements.first.offender_no).to eq('1')
    end

    it 'can return multiple movements for a specific offender',
       vcr: { cassette_name: :movement_api_multiple_movements } do
      movements = described_class.movements_for('G1670VU')

      expect(movements).to be_kind_of(Array)
      expect(movements.length).to eq(5)
      expect(movements.first).to be_kind_of(Nomis::Movement)
    end
  end

  describe 'Movements for multiple offenders' do
    it 'can get movements for multiple offenders', vcr: { cassette_name: :movement_api_for_multiple_offenders } do
      movements = described_class.movements_for(%w[A5019DY G7806VO])

      expect(movements).to be_kind_of(Array)
      expect(movements.length).to eq(7)
      expect(movements.first).to be_kind_of(Nomis::Movement)
    end
  end
end
